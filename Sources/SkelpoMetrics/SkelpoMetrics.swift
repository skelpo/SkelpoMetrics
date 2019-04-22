import Foundation

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
