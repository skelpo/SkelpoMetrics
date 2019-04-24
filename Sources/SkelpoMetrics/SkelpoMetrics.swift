import Foundation
import Metrics

public struct Error: Swift.Error {
    public let identifier: String
    public let reason: String

    public init(identifier: String, reason: String) {
        self.identifier = identifier
        self.reason = reason
    }
}

public struct Config {
    public let url: String
    public let key: String
    public let id: String

    public init(url: String, key: String, id: String) {
        self.url = url
        self.key = key
        self.id = id
    }

    public init(url: String? = nil)throws {
        guard let url = url ?? ProcessInfo.processInfo.environment["SKELPO_METRICS_URL"] else {
            throw Error(identifier: "missingEnvVar", reason: "Could not get value for `SKELPO_METRICS_URL` env var")
        }
        guard let key = ProcessInfo.processInfo.environment["SKELPO_METRICS_KEY"] else {
            throw Error(identifier: "missingEnvVar", reason: "Could not get value for `SKELPO_METRICS_KEY` env var")
        }
        guard let id = ProcessInfo.processInfo.environment["SKELPO_METRICS_ID"] else {
            throw Error(identifier: "missingEnvVar", reason: "Could not get value for `SKELPO_METRICS_ID` env var")
        }

        self.url = url
        self.key = key
        self.id = id
    }
}

public struct SkelpoMetric {
    public let config: Config
    private let client: Client

    public init(config: Config) {
        self.config = config
        self.client = Client()
    }

    public func record(_ guage: SkelpoMetricFactory.Guage, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        self.record(.guage(value: guage.value), closure)
    }

    public func record(_ timer: SkelpoMetricFactory.Timer, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        self.record(.timer(durations: timer.durations), closure)
    }

    public func record(_ counter: SkelpoMetricFactory.Counter, _ closure: @escaping (Result<Void, Swift.Error>) -> ()) {
        self.record(.counter(value: counter.value), closure)
    }

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

public struct SkelpoMetricFactory: MetricsFactory {
    public func makeCounter(label: String, dimensions: [(String, String)]) -> CounterHandler {
        return Counter(label: label)
    }

    public func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        return aggregate ? Recorder(label: label) : Guage(label: label)
    }

    public func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        return Timer(label: label)
    }

    public func destroyCounter(_ handler: CounterHandler) { }
    public func destroyRecorder(_ handler: RecorderHandler) { }
    public func destroyTimer(_ handler: TimerHandler) { }

    public final class Counter: CounterHandler {
        let label: String
        private(set) var value: Int64

        init(label: String) {
            self.label = label
            self.value = 0
        }

        public func increment(by increment: Int64) {
            self.value += increment
        }

        public func reset() {
            self.value = 0
        }
    }

    public final class Recorder: RecorderHandler {
        let label: String
        private(set) var value: [Double]

        init(label: String) {
            self.label = label
            self.value = []
        }

        public func record(_ value: Int64) {
            self.value.append(Double(value))
        }

        public func record(_ value: Double) {
            self.value.append(value)
        }
    }

    public final class Guage: RecorderHandler {
        let label: String
        private(set) var value: Double

        init(label: String) {
            self.label = label
            self.value = 0
        }

        public func record(_ value: Int64) {
            self.value = Double(value)
        }

        public func record(_ value: Double) {
            self.value = value
        }
    }

    public final class Timer: TimerHandler {
        let label: String
        private(set) var durations: [Int64]

        init(label: String) {
            self.label = label
            self.durations = []
        }

        public func recordNanoseconds(_ duration: Int64) {
            self.durations.append(duration)
        }
    }
}
