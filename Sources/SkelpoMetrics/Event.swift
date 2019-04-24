import Foundation

public struct Event: Codable {
    public var attributes: [String: String] = [:]
    public var quantity: Int = 1
    public var date: Date = Date()

    public var metric: Metric?
    public var type: String

    public init(metric: Metric) {
        self.metric = metric
        self.type = "metric"
    }

    public init(type: String) {
        self.metric = nil
        self.type = type
    }
}

public enum Metric: Codable, Hashable {
    public enum Name: String, Codable, CaseIterable {
        case guage
        case timer
        case counter
        case recorder
    }

    case guage(value: Double)
    case timer(durations: [Int64])
    case counter(value: Int64)
    case recorder(values: [Double])

    public var name: Name {
        switch self {
        case .guage(_): return .guage
        case .timer(_): return .timer
        case .counter(_): return .counter
        case .recorder(_): return .recorder
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        switch try container.decode(Name.self, forKey: .name) {
        case .guage: self = try .guage(value: container.decode(Double.self, forKey: .value))
        case .timer: self = try .timer(durations: container.decode([Int64].self, forKey: .value))
        case .counter: self = try .counter(value: container.decode(Int64.self, forKey: .value))
        case .recorder: self = try .recorder(values: container.decode([Double].self, forKey: .value))
        }
    }

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

    public enum CodingKeys: String, CodingKey {
        case name, value
    }
}
