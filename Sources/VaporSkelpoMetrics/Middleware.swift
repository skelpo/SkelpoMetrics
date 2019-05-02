import SkelpoMetrics
import Vapor

/// A middleware that stores metric data from an API call.
///
/// For this middleware to work, you will need to register `SwiftMetrics.Config` as
/// a service with your app's `Services` instance.
///
/// This middleware must be registered per container to your app's `Services` instance:
///
///     services.register(SkelpoMetricsMiddleware.self)
public final class SkelpoMetricsMiddleware: Middleware, ServiceType {
    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        if #available(OSX 10.12, *) {
            encoder.dateEncodingStrategy = .iso8601
        } else {
            encoder.dateEncodingStrategy = .custom { date, _encoder in
                var container = _encoder.singleValueContainer()
                try container.encode(date.timeIntervalSince1970.description)
            }
        }
        return encoder
    }()

    /// See `ServiceType.makeService(for:)`.
    public static func makeService(for container: Container) throws -> SkelpoMetricsMiddleware {
        return try SkelpoMetricsMiddleware(
            encoder: try? container.make(ContentCoders.self).requireDataEncoder(for: .json),
            config: container.make(),
            logger: container.make(),
            client: container.make()
        )
    }

    private let config: SkelpoMetrics.Config
    private let encoder: DataEncoder
    private let logger: Logger
    private let client: Client

    private init(encoder: DataEncoder?, config: SkelpoMetrics.Config, logger: Logger, client: Client) {
        self.encoder = encoder ?? SkelpoMetricsMiddleware.jsonEncoder
        self.config = config
        self.logger = logger
        self.client = client
    }

    /// See `Middleware.respond(to:chainingTo:)`.
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        var event = Event(type: "request")
        event.locked = true

        return try next.respond(to: request).flatMap { response in
            event.attributes["status"] = response.http.status.code.description
            event.attributes["endpoint"] = request.http.urlString
            event.metric = .timer(durations: [Int64(Date().timeIntervalSince1970 - event.date.timeIntervalSince1970)])

            let body: Data
            do { body = try self.encoder.encode(event) }
            catch let error {
                self.logger.error("Metric event failed to save with error: \(error.localizedDescription)")
                return request.future(response)
            }

            let http = HTTPRequest(
                method: .POST,
                url: self.config.url,
                headers: ["Authorization": self.config.key, "Content-Type": "application/json"],
                body: body
            )

            return self.client.send(Request(http: http, using: request)).map { event in
                guard (200..<300).contains(event.http.status.code) else {
                    self.logger.error("Got a \(event.http.status.code) response when creating `Event` model.")
                    return response
                }

                return response
            }.catchMap { error in
                self.logger.error("Metric event failed to save with error: \(error.localizedDescription)")
                return response
            }
        }
    }
}
