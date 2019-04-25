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

    /// The root URL for the API to save the metrics to.
    public let url: String

    /// The key for the API that the metrics will be saved to.
    public let key: String

    /// Creates a new `Config` instance.
    ///
    /// - Parameters:
    ///   - url: The root URL for the API to save the metrics to.
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

/// Stores metric data to the configured API.
public final class SkelpoMetric {

    /// The `Config` instance with the API root and API key to use when storing the metric data.
    public let config: Config

    private let client: Client

    /// Creates a new `SkelpoMetric` instance.
    ///
    /// - Parameter config: The `Config` instance with the API root and API key to use when storing the metric data.
    public init(config: Config) {
        self.config = config
        self.client = Client()
    }

    /// Stores an `Event` object in the configured API, using the value of the guage passed in as the metric.
    ///
    /// - Parameters:
    ///   - guage: The guage whos value will be used in the metric that will be stored.
    ///   - closure: The closure that will be called when the metric storage completes.
    public func record(_ guage: SkelpoMetricFactory.Guage, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        self.record(.guage(value: guage.value), closure)
    }

    /// Stores an `Event` object in the configured API, using the durations of the timer passed in as the metric.
    ///
    /// - Parameters:
    ///   - guage: The timer whos durations will be used in the metric that will be stored.
    ///   - closure: The closure that will be called when the metric storage completes.
    public func record(_ timer: SkelpoMetricFactory.Timer, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        self.record(.timer(durations: timer.durations), closure)
    }

    /// Stores an `Event` object in the configured API, using the value of the counter passed in as the metric.
    ///
    /// - Parameters:
    ///   - guage: The counter whos value will be used in the metric that will be stored.
    ///   - closure: The closure that will be called when the metric storage completes.
    public func record(_ counter: SkelpoMetricFactory.Counter, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        self.record(.counter(value: counter.value), closure)
    }

    /// Stores an `Event` object in the configured API, using the values of the recorder passed in as the metric.
    ///
    /// - Parameters:
    ///   - guage: The recorder whos values will be used in the metric that will be stored.
    ///   - closure: The closure that will be called when the metric storage completes.
    public func record(_ recorder: SkelpoMetricFactory.Recorder, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        self.record(.recorder(values: recorder.value), closure)
    }

    private func record(_ metric: Metric, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        let body = Event(metric: metric)
        self.client.send(
            "POST",
            url: self.config.url + "/events",
            headers: ["Content-Type": "application/json", "Authorization": self.config.key],
            body: body,
            closure
        )
    }
}

/// The `MetricFactory` instance that should be registered
public struct SkelpoMetricFactory: MetricsFactory {

    /// See `MetricsFactory.makeCounter(label:dimensions:)`.
    public func makeCounter(label: String, dimensions: [(String, String)]) -> CounterHandler {
        return Counter(label: label)
    }

    /// See `MetricsFactory.makeRecorder(label:dimensions:aggregate:)`.
    public func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        return aggregate ? Recorder(label: label) : Guage(label: label)
    }

    /// See `MetricsFactory.makeTimer(label:dimensions:)`.
    public func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        return Timer(label: label)
    }

    /// See `MetricsFactory.destroyCounter(_:)`.
    public func destroyCounter(_ handler: CounterHandler) { }

    /// See `MetricsFactory.destroyRecorder(_:)`.
    public func destroyRecorder(_ handler: RecorderHandler) { }

    /// See `MetricsFactory.destroyTimer(_:)`.
    public func destroyTimer(_ handler: TimerHandler) { }

    /// A `CounterHandler` that tracks a value that can be stored as a metric by `SwiftMetrics`.
    public final class Counter: CounterHandler {
        let label: String
        private(set) var value: Int64

        init(label: String) {
            self.label = label
            self.value = 0
        }

        /// See `CounterHandler.increment(by:)`.
        public func increment(by increment: Int64) {
            self.value += increment
        }

        /// See `CounterHandler.reset()`.
        public func reset() {
            self.value = 0
        }
    }

    /// A `RecorderHandler` that records aggregate values that can be stored as a metric by `SwiftMetrics`.
    public final class Recorder: RecorderHandler {
        let label: String
        private(set) var value: [Double]

        init(label: String) {
            self.label = label
            self.value = []
        }

        /// See `RecorderHandler.record(_:)`.
        public func record(_ value: Int64) {
            self.value.append(Double(value))
        }

        /// See `RecorderHandler.record(_:)`
        public func record(_ value: Double) {
            self.value.append(value)
        }
    }

    /// A `RecorderHandler` that records a single value that can be stored as a metric by `SwiftMetrics`.
    public final class Guage: RecorderHandler {
        let label: String
        private(set) var value: Double

        init(label: String) {
            self.label = label
            self.value = 0
        }

        /// See `RecorderHandler.record(_:)`.
        public func record(_ value: Int64) {
            self.value = Double(value)
        }

        /// See `RecorderHandler.record(_:)`.
        public func record(_ value: Double) {
            self.value = value
        }
    }

    /// A `TimerHandler` that records a list of durations that can be stored as a metric by `SwiftMetrics`.
    public final class Timer: TimerHandler {
        let label: String
        private(set) var durations: [Int64]

        init(label: String) {
            self.label = label
            self.durations = []
        }

        /// See `TimerHandler.recordNanoseconds(_:)`.
        public func recordNanoseconds(_ duration: Int64) {
            self.durations.append(duration)
        }
    }
}
