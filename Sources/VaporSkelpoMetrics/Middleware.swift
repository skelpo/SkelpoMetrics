import SkelpoMetrics
import Vapor

public final class SkelpoMetricsMiddleware: Middleware {
    public init() { }

    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let config = try request.make(SkelpoMetrics.Config.self)
        let logger = try request.make(Logger.self)
        let client = try request.make(Client.self)

        var event = Event(date: Date(), type: "request", quantity: 1, attributes: [:])

        return try next.respond(to: request).flatMap { response in
            event.attributes["status"] = response.http.status.code.description
            event.attributes["endpoint"] = request.http.urlString
            event.attributes["interval"] = String(describing: Date().timeIntervalSince1970 - event.date.timeIntervalSince1970)

            let body: Data
            do { body = try JSONEncoder().encode(event) }
            catch let error {
                logger.error("Metric event failed to save with error: \(error.localizedDescription)")
                return request.future(response)
            }

            let http = HTTPRequest(method: .POST, url: config.url, headers: ["Authorization": config.key], body: body)
            return client.send(Request(http: http, using: request)).transform(to: response).catchMap { error in
                logger.error("Metric event failed to save with error: \(error.localizedDescription)")
                return response
            }
        }
    }
}

internal struct Event: Content {
    var date: Date
    var type: String
    var quantity: Int
    var attributes: [String: String]
}
