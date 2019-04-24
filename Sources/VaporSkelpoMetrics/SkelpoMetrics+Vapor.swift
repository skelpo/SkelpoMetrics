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

extension SkelpoMetrics.SkelpoMetric {
    public func record(_ guage: SkelpoMetricFactory.Guage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.newPromise(Void.self)
        self.record(guage) { result in
            switch result {
            case let .failure(error): promise.fail(error: error)
            case .success: promise.succeed()
            }
        }
        return promise.futureResult
    }

    public func record(_ timer: SkelpoMetricFactory.Timer, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.newPromise(Void.self)
        self.record(timer) { result in
            switch result {
            case let .failure(error): promise.fail(error: error)
            case .success: promise.succeed()
            }
        }
        return promise.futureResult
    }

    public func record(_ counter: SkelpoMetricFactory.Counter, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.newPromise(Void.self)
        self.record(counter) { result in
            switch result {
            case let .failure(error): promise.fail(error: error)
            case .success: promise.succeed()
            }
        }
        return promise.futureResult
    }

    public func record(_ recorder: SkelpoMetricFactory.Recorder, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.newPromise(Void.self)
        self.record(recorder) { result in
            switch result {
            case let .failure(error): promise.fail(error: error)
            case .success: promise.succeed()
            }
        }
        return promise.futureResult
    }
}
