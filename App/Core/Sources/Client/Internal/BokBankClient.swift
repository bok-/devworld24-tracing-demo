
import AsyncHTTPClient
import Foundation
import HTTPTypes
import HummingbirdWSClient
import Logging
import Models
import NIOCore
import NIOHTTP1
import NIOTransportServices
import OTel
import Tracing
import TracingOpenTelemetrySemanticConventions

actor BokBankClient {

    // MARK: - Properties

    let endpoint: Endpoint
    let user: User.ID
    let httpClient: HTTPClient

    let userAgent = "BokBank/1.0"

    // MARK: - Initialisation

    init(endpoint: Endpoint, user: User.ID) {
        self.endpoint = endpoint
        self.user = user
        self.httpClient = HTTPClient(eventLoopGroupProvider: .shared(NIOTSEventLoopGroup.singleton))
    }

    deinit {
        try! httpClient.syncShutdown()
    }

    // MARK: - Execution

    func execute<Response>(
        _ path: String,
        method: HTTPMethod,
        headers: HTTPHeaders,
        body: ByteBuffer? = nil,
        timeout: TimeAmount = .seconds(30)
    ) async throws -> Response where Response: Decodable {
        try await withSpan("\(method.rawValue) \(path)", ofKind: .client) { span in
            // Record target info
            span.updateAttributes { attributes in
                attributes.http.host = endpoint.host
                attributes.http.scheme = endpoint.scheme
                attributes.http.userAgent = userAgent
                attributes.http.method = method.rawValue
                attributes.http.target = path
            }

            // Create request
            var request = HTTPClientRequest(url: "\(endpoint.scheme)://\(endpoint.host):\(endpoint.port)\(path)")
            request.method = method
            if let body {
                request.body = .bytes(body)
            }

            var headers = headers
            headers.add(contentsOf: [
                "X-BokBank-User-ID": user,
                "User-Agent": userAgent,
            ])

            // Propagate trace headers
            if let spanContext = span.context.spanContext {
                OTelW3CPropagator().inject(spanContext, into: &headers, using: HTTPHeadersInjector())
            }

            request.headers = headers

            // Record request info
            span.updateAttributes { attributes in
                for (name, value) in headers {
                    attributes.http.request.headers.setValues([ value ], forHeader: name)
                }
                if let body {
                    attributes.http.request.uncompressedContentLength = body.readableBytes
                }
            }

            let response = try await httpClient.execute(request, timeout: timeout)
            let maxLength = response.headers.first(name: "Content-Length").flatMap(Int.init) ?? (1024 * 1024)
            let body = try await response.body.collect(upTo: maxLength)
            guard let decoded = try body.getJSONDecodable(Response.self, decoder: .init(), at: 0, length: body.readableBytes) else {
                throw APIError.emptyResponse
            }

            // Record response info
            span.updateAttributes { attributes in
                attributes.http.statusCode = Int(response.status.code)
                for (name, value) in response.headers {
                    attributes.http.response.headers.setValues([ value ], forHeader: name)
                }
                attributes.http.response.uncompressedContentLength = body.readableBytes
            }
            return decoded
        }
    }

    func get<Response>(
        _ path: String,
        timeout: TimeAmount = .seconds(30)
    ) async throws -> Response where Response: Decodable {
        try await execute(
            path,
            method: .GET,
            headers: [:]
        )
    }

    func post<Request, Response>(
        _ path: String,
        request body: Request,
        timeout: TimeAmount = .seconds(30)
    ) async throws -> Response where Request: Encodable, Response: Decodable {
        var encoded = ByteBuffer()
        try encoded.writeJSONEncodable(body)
        return try await execute(
            path,
            method: .POST,
            headers: [
                "Content-Type": "application/json",
            ],
            body: encoded
        )
    }


    // MARK: - Web Sockets

    func connect<Message>(_ path: String, handler: @Sendable @escaping (Message) async throws -> Void) async throws where Message: Decodable {
        try await WebSocketClient.connect(
            url: "\(endpoint.scheme)://\(endpoint.host):\(endpoint.port)\(path)",
            configuration: .init(
                additionalHeaders: [
                    HTTPField.Name("X-BokBank-User-ID")!: user,
                    HTTPField.Name.userAgent: userAgent,
                ],
                autoPing: .enabled(timePeriod: .seconds(10))
            ),
            eventLoopGroup: NIOTSEventLoopGroup.singleton,
            logger: Logger(label: "syncclient")
        ) { stream, _, _ in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                for try await frame in stream {
                    let message = try decoder.decode(Message.self, from: frame.data)
                    try await handler(message)
                }
            } catch {
                print("Error decoding websocket message: \(error)")
                throw error
            }
        }
    }

}


// MARK: - Errors

extension BokBankClient {
    enum APIError: Error {
        case emptyResponse
    }
}
