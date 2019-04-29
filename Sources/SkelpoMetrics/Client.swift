import Foundation

internal struct Client {
    let session: URLSession = URLSession(configuration: .default)

    func send(
        _ method: String,
        url string: String,
        headers: [String: String],
        _ complete: @escaping (Result<Void, Swift.Error>) -> ()
    ) {
        self.send(method, url: string, headers: headers, body: Optional<[String: String]>.none, complete)
    }

    func send<Body>(
        _ method: String,
        url string: String,
        headers: [String: String],
        body: Body?,
        _ complete: @escaping (Result<Void, Swift.Error>) -> ()
    ) where Body: Codable {
        guard let url = URL(string: string) else {
            return complete(.failure(Error(identifier: "badURL", reason: "Unable to create URL from string `\(string)`")))
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        headers.forEach { header in
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }

        do {
            request.httpBody = try body.map(JSONEncoder().encode)
        } catch let error {
            return complete(.failure(error))
        }

        return self.session.dataTask(with: request) { data, response, error in
            if let error = error {
                return complete(.failure(error))
            }
            guard let response = response as? HTTPURLResponse else {
                return complete(.failure(Error(identifier: "unknownResponse", reason: "Response received not from HTTP")))
            }

            guard (200...299).contains(response.statusCode) else {
                return complete(
                    .failure(Error(identifier: "failedOperation", reason: "Received status code `\(response.statusCode)`"))
                )
            }
            
            return complete(.success(()))
        }.resume()
    }
}
