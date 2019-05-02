import Foundation
import Metrics

/// An error that occurs from a failed operation in the SkelpoMetrics API.
public struct Error: Swift.Error {

    /// The identifier for the error that is machine readable.
    public let identifier: String

    /// The human readable reason for the error.
    public let reason: String

    /// Created a new `SwiftMetrics.Error` instance.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the error.
    ///   - reason: The human readable reason for the error.
    public init(identifier: String, reason: String) {
        self.identifier = identifier
        self.reason = reason
    }
}

/// A configuration for a `SkelpoMetric` instance.
public struct Config {

    /// The name of the environment variable that the `url` property
    /// value will be read from in the `Config.init(url:)` initializer.
    public static var urlVariable: String = "SKELPO_METRICS_URL"

    /// The name of the environment variable that the `key` property
    /// value will be read from in the `Config.init(url:)` initializer.
    public static var keyVariable: String = "SKELPO_METRICS_KEY"

    /// The host and resource for the API to save the metrics to.
    ///
    /// I.e. `https://metrics.skelpo.com/api/v1/events`.
    public let url: String

    /// The key for the API that the metrics will be saved to.
    public let key: String

    /// Creates a new `Config` instance.
    ///
    /// - Parameters:
    ///   - url: The host and resource for the API to save the metrics to.
    ///   - key: The key for the API that the metrics will be saved to.
    public init(url: String, key: String) {
        self.url = url
        self.key = key
    }

    /// Creates a new `Config` instance from environment variables.
    public init()throws {
        guard let url = ProcessInfo.processInfo.environment[Config.urlVariable] else {
            throw Error(identifier: "missingEnvVar", reason: "Could not get value for `\(Config.urlVariable)` env var")
        }
        guard let key = ProcessInfo.processInfo.environment[Config.keyVariable] else {
            throw Error(identifier: "missingEnvVar", reason: "Could not get value for `\(Config.keyVariable)` env var")
        }

        self.url = url
        self.key = key
    }
}

/// The `MetricFactory` instance that should be registered to store metric information
/// to a `skelpo/metric` API instance.
public struct SkelpoMetric: MetricsFactory {

    /// The configuration for the metric factory with the URL for the API at
    /// which to store the metric and the key for the API.
    public let config: Config

    /// Creates a new `SkelpoMetric` instance.
    ///
    /// - Parameter config: The configuration for the metric factory.
    public init(config: Config) {
        self.config = config
    }

    /// See `MetricsFactory.makeCounter(label:dimensions:)`.
    public func makeCounter(label: String, dimensions: [(String, String)]) -> CounterHandler {
        return Counter(label: label, config: self.config)
    }

    /// See `MetricsFactory.makeRecorder(label:dimensions:aggregate:)`.
    public func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        return aggregate ? Recorder(label: label, config: self.config) : Guage(label: label, config: self.config)
    }

    /// See `MetricsFactory.makeTimer(label:dimensions:)`.
    public func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        return Timer(label: label, config: self.config)
    }

    /// See `MetricsFactory.destroyCounter(_:)`.
    public func destroyCounter(_ handler: CounterHandler) {
        if let counter = handler as? Counter { counter.lock() }
    }

    /// See `MetricsFactory.destroyRecorder(_:)`.
    public func destroyRecorder(_ handler: RecorderHandler) {
        if let recorder = handler as? Recorder {
            recorder.lock()
        } else if let guage = handler as? Guage {
            guage.lock()
        }
    }

    /// See `MetricsFactory.destroyTimer(_:)`.
    public func destroyTimer(_ handler: TimerHandler) {
        if let timer = handler as? Timer { timer.lock() }
    }

    /// A `CounterHandler` that tracks a value that can be stored as a metric by `SwiftMetrics`.
    public final class Counter: CounterHandler {
        private let state: MetricState

        init(label: String, config: Config) {
            self.state = MetricState(label: label, config: config)
        }

        /// See `CounterHandler.increment(by:)`.
        public func increment(by increment: Int64) {
            let operation: MetricState.Operation = { complete in
                if let event = self.state.event {
                    self.state.client.send(
                        "PATCH",
                        url: self.state.config.url + "/\(event)/increment?by=\(increment)",
                        headers: ["Authorization": self.state.config.key, "Content-Type": "application/json"],
                        complete
                    )
                } else {
                    self.state.config.createEvent(metric: .counter(value: increment), on: self.state.client, complete)
                }
            }
            self.state.run(operation: operation)
        }

        /// See `CounterHandler.reset()`.
        public func reset() {
            let operation: MetricState.Operation = { complete in
                if let event = self.state.event {
                    self.state.client.send(
                        "PATCH",
                        url: self.state.config.url + "/\(event)/reset",
                        headers: ["Authorization": self.state.config.key, "Content-Type": "application/json"],
                        complete
                    )
                } else {
                    self.state.config.createEvent(metric: .counter(value: 0), on: self.state.client, complete)
                }
            }
            self.state.run(operation: operation)
        }

        /// Locks the metric's event to stop mutations. so it can be aggregated.
        public func lock() {
            self.state.lock()
        }
    }

    /// A `RecorderHandler` that records aggregate values that can be stored as a metric by `SwiftMetrics`.
    public final class Recorder: RecorderHandler {
        private let state: MetricState

        init(label: String, config: Config) {
            self.state = MetricState(label: label, config: config)
        }

        /// See `RecorderHandler.record(_:)`.
        public func record(_ value: Int64) {
            self.record(Double(value))
        }

        /// See `RecorderHandler.record(_:)`
        public func record(_ value: Double) {
            let operation: MetricState.Operation = { complete in
                if let event = self.state.event {
                    self.record(value: value, on: event, complete)
                } else {
                    self.state.config.createEvent(metric: .recorder(values: [value]), on: self.state.client, complete)
                }
            }
            self.state.run(operation: operation)
        }

        /// Locks the metric's event to stop mutations. so it can be aggregated.
        public func lock() {
            self.state.lock()
        }

        private func record(value: Double, on event: Int, _ callback: @escaping (Result<Void, Swift.Error>) -> ()) {
            self.state.client.send(
                "PATCH",
                url: self.state.config.url + "/\(event)/record/\(value)",
                headers: ["Authorization": self.state.config.key, "Content-Type": "application/json"],
                callback
            )
        }
    }

    /// A `RecorderHandler` that records a single value that can be stored as a metric by `SwiftMetrics`.
    public final class Guage: RecorderHandler {
        private let state: MetricState

        init(label: String, config: Config) {
            self.state = MetricState(label: label, config: config)
        }

        /// See `RecorderHandler.record(_:)`.
        public func record(_ value: Int64) {
            self.record(Double(value))
        }

        /// See `RecorderHandler.record(_:)`.
        public func record(_ value: Double) {
            let operation: MetricState.Operation = { complete in
                if let event = self.state.event {
                    self.record(value: value, on: event, complete)
                } else {
                    self.state.config.createEvent(metric: .guage(value: value), on: self.state.client, complete)
                }
            }
            self.state.run(operation: operation)
        }

        /// Locks the metric's event to stop mutations. so it can be aggregated.
        public func lock() {
            self.state.lock()
        }

        private func record(value: Double, on event: Int, _ callback: @escaping (Result<Void, Swift.Error>) -> ()) {
            self.state.client.send(
                "PATCH",
                url: self.state.config.url + "/\(event)/record/\(value)",
                headers: ["Authorization": self.state.config.key, "Content-Type": "application/json"],
                callback
            )
        }
    }

    /// A `TimerHandler` that records a list of durations that can be stored as a metric by `SwiftMetrics`.
    public final class Timer: TimerHandler {
        private let state: MetricState

        init(label: String, config: Config) {
            self.state = MetricState(label: label, config: config)
        }

        /// See `TimerHandler.recordNanoseconds(_:)`.
        public func recordNanoseconds(_ duration: Int64) {
            let operation: MetricState.Operation = { complete in
                if let event = self.state.event {
                    self.record(duration: duration, on: event, complete)
                } else {
                    self.state.config.createEvent(metric: .timer(durations: [duration]), on: self.state.client, complete)
                }
            }
            self.state.run(operation: operation)
        }

        /// Locks the metric's event to stop mutations. so it can be aggregated.
        public func lock() {
            self.state.lock()
        }

        private func record(duration: Int64, on event: Int, _ callback: @escaping (Result<Void, Swift.Error>) -> ()) {
            self.state.client.send(
                "PATCH",
                url: self.state.config.url + "/\(event)/record/\(duration)",
                headers: ["Authorization": self.state.config.key, "Content-Type": "application/json"],
                callback
            )
        }
    }

    private final class MetricState {
        typealias Operation = (@escaping (Result<Void, Swift.Error>) -> ()) -> ()

        let label: String
        let config: Config

        var running: Bool
        let client: Client
        var event: Int?
        var queue: [Operation]

        init(label: String, config: Config) {
            self.label = label
            self.config = config

            self.running = false
            self.client = Client()
            self.event = nil
            self.queue = []
        }

        func run(operation: @escaping Operation) {
            self.queue.append(operation)
            if !self.running {
                self.running = true
                self._run()
            }
        }

        private func _run() {
            guard self.queue.count > 0 else { return (self.running = false) }
            let operation = self.queue.removeFirst()

            return operation { result in
                if case let .failure(error) = result {
                    print(error)
                }

                self._run()
            }
        }

        func lock() {
            let operation: MetricState.Operation = { complete in
                guard let event = self.event else {
                    let error = Error(
                        identifier: "noEvent",
                        reason: "The current metric doesn't have a connected event, so it can't be locked."
                    )
                    return complete(.failure(error))
                }

                self.client.send(
                    "PATCH",
                    url: self.config.url + "/\(event)/lock",
                    headers: ["Authorization": self.config.key, "Content-Type": "application/json"],
                    complete
                )
            }

            self.queue.append(operation)
        }
    }
}

extension Config {
    internal func createEvent(metric: Metric, on client: Client, _ complete: @escaping (Result<Void, Swift.Error>) -> ()) {
        let body = Event(metric: metric)
        client.send(
            "POST",
            url: self.url,
            headers: ["Content-Type": "application/json", "Authorization": self.key],
            body: body,
            complete
        )
    }
}
