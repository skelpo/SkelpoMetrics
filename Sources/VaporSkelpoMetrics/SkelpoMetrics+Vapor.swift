@_exported import SkelpoMetrics
import Vapor

extension SkelpoMetrics.Error: AbortError {

    /// See `AbortError.HTTPResponseStatus`.
    public var status: HTTPResponseStatus {
        switch self.identifier {
        default: return .internalServerError
        }
    }
}

extension SkelpoMetrics.Config: ServiceType {

    /// See `ServiceType.makeService(for:)`.
    public static func makeService(for container: Container) throws -> SkelpoMetrics.Config {
        return try .init()
    }
}
