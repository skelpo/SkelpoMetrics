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

    /// See `ServiceType.makeService(for:)`.
    public static func makeService(for container: Container) throws -> SkelpoMetricsMiddleware {
        return try SkelpoMetricsMiddleware(config: container.make(), logger: container.make(), client: container.make())
    }

    private let config: SkelpoMetrics.Config
    private let logger: Logger
    private let client: Client

    private init(config: SkelpoMetrics.Config, logger: Logger, client: Client) {
        self.config = config
        self.logger = logger
        self.client = client
    }

    /// See `Middleware.respond(to:chainingTo:)`.
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        var event = Event(type: "request")
        return try next.respond(to: request).flatMap { response in
            event.attributes["status"] = response.http.status.code.description
            event.attributes["endpoint"] = request.http.urlString
            event.metric = .timer(durations: [Int64(Date().timeIntervalSince1970 - event.date.timeIntervalSince1970)])

            let body: Data
            do { body = try JSONEncoder().encode(event) }
            catch let error {
                self.logger.error("Metric event failed to save with error: \(error.localizedDescription)")
                return request.future(response)
            }

            let http = HTTPRequest(method: .POST, url: self.config.url, headers: ["Authorization": self.config.key], body: body)
            return self.client.send(Request(http: http, using: request)).transform(to: response).catchMap { error in
                self.logger.error("Metric event failed to save with error: \(error.localizedDescription)")
                return response
            }
        }
    }
}
