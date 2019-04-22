@_exported import SkelpoMetrics
import Vapor

extension SkelpoMetrics.Error: AbortError {
    public var status: HTTPResponseStatus {
        switch self.identifier {
        case "missingEnvVar": return .internalServerError
        default: return .internalServerError
        }
    }
}

extension SkelpoMetrics.Config: ServiceType {
    public static func makeService(for container: Container) throws -> SkelpoMetrics.Config {
        return try .init()
    }
}
