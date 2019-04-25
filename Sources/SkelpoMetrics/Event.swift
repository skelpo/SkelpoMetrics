import Foundation

/// An event that occurs at a given point in time. This is the model used by the Skelpo `metric` API.
public struct Event: Codable {

    /// Arbitrary key/value pairs for the given `Event`.
    public var attributes: [String: String] = [:]

    /// The number of the given event that have occured.
    public var quantity: Int = 1

    /// The date that the event occured at.
    public var date: Date = Date()

    /// The metric that is connected to the given event.
    public var metric: Metric?

    /// The type that describes what event occured.
    public var type: String

    /// Creates a new `Event` instance.
    ///
    /// This initializer assigns the `type` property the value `"metric"`.
    ///
    /// - Parameter metric: The metric that will be connected to event.
    public init(metric: Metric) {
        self.metric = metric
        self.type = "metric"
    }

    /// Creates a new `Event` instance.
    ///
    /// This initializer assigns the `metric` value to `nil`.
    ///
    /// - Parameter type: The Event's type that will be used.
    public init(type: String) {
        self.metric = nil
        self.type = type
    }
}

/// A recorded metric from a `SkelpoMetric` metric handler type.
public enum Metric: Codable, Hashable {

    /// The names of the metric cases without the associated types.
    public enum Name: String, Codable, CaseIterable {

        /// The name for the `Metric.guage` case.
        case guage

        /// The name for the `Metric.timer` case.
        case timer

        /// The name for the `Metric.counter` case.
        case counter

        /// The name for the `Metric.recorder` case.
        case recorder
    }

    /// The stored value from a `SkelpoMetricFactory.Guage` instance.
    case guage(value: Double)

    /// The stored durations from a `SkelpoMetricFactory.Timer` instance.
    case timer(durations: [Int64])

    /// The stored value from a `SkelpoMetricFactory.Counter` instance.
    case counter(value: Int64)

    /// The stored values from a `SkelpoMetricFactory.Recorder` instance.
    case recorder(values: [Double])

    /// Get the `Name` case for the given `Metric`.
    public var name: Name {
        switch self {
        case .guage(_): return .guage
        case .timer(_): return .timer
        case .counter(_): return .counter
        case .recorder(_): return .recorder
        }
    }

    /// See [`Decodable.init(from:)`](https://developer.apple.com/documentation/swift/decodable/2894081-init).
    ///
    /// The case to decode the figured by decoding the `.name` coding key to `Name` case.
    /// The case's associated value is decoded from the `.value` coding key.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        switch try container.decode(Name.self, forKey: .name) {
        case .guage: self = try .guage(value: container.decode(Double.self, forKey: .value))
        case .timer: self = try .timer(durations: container.decode([Int64].self, forKey: .value))
        case .counter: self = try .counter(value: container.decode(Int64.self, forKey: .value))
        case .recorder: self = try .recorder(values: container.decode([Double].self, forKey: .value))
        }
    }

    /// See [`Encodable.encode(to:)`](https://developer.apple.com/documentation/swift/encodable/2893603-encode).
    ///
    /// Encodes the `Name` for the given case to the `.name ` coding key and the associated value to the `.value` coding key.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .guage(value): try container.encode(value, forKey: .value)
        case let .timer(durations): try container.encode(durations, forKey: .value)
        case let .counter(value): try container.encode(value, forKey: .value)
        case let .recorder(values): try container.encode(values, forKey: .value)
        }

        try container.encode(self.name, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case name, value
    }
}
