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

extension SkelpoMetrics.SkelpoMetric {

    /// Saves a guage's value to the configured metric API on an event-loop.
    ///
    /// - Parameters:
    ///   - guage: The guage whos data will be saved to the API.
    ///   - eventLoop: The event-loop that the future which is returned will live on.
    ///
    /// - Returns: A void `EventLoopFuture`, which succeedes when the storage completes.
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

    /// Saves a timer's durations to the configured metric API on an event-loop.
    ///
    /// - Parameters:
    ///   - timer: The timer whos data will be saved to the API.
    ///   - eventLoop: The event-loop that the future which is returned will live on.
    ///
    /// - Returns: A void `EventLoopFuture`, which succeedes when the storage completes.
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

    /// Saves a counter's value to the configured metric API on an event-loop.
    ///
    /// - Parameters:
    ///   - counter: The counter whos data will be saved to the API.
    ///   - eventLoop: The event-loop that the future which is returned will live on.
    ///
    /// - Returns: A void `EventLoopFuture`, which succeedes when the storage completes.
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

    /// Saves a recorder's values to the configured metric API on an event-loop.
    ///
    /// - Parameters:
    ///   - recorder: The recorder whos data will be saved to the API.
    ///   - eventLoop: The event-loop that the future which is returned will live on.
    ///
    /// - Returns: A void `EventLoopFuture`, which succeedes when the storage completes.
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
