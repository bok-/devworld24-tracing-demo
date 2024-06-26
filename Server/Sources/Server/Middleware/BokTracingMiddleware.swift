//===----------------------------------------------------------------------===//
//
// This source file is part of a technology demo for /dev/world 2024.
//
// Copyright © 2024 ANZ. All rights reserved.
// Licensed under the MIT license
//
// See LICENSE for license information
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import HTTPTypes
import Hummingbird
import NIOCore
import Tracing

/// Middleware creating Distributed Tracing spans for each request.
///
/// Creates a span for each request, including attributes such as the HTTP method.
///
/// You may opt in to recording a specific subset of HTTP request/response header values by passing
/// a set of header names.
///
/// We forked this from Hummingbird's `TracingMiddleware` so we can add support for including the authenticated
/// user in the attributes.
///
struct BokTracingMiddleware: RouterMiddleware {
    private let headerNamesToRecord: Set<RecordingHeader>
    private let attributes: SpanAttributes?

    /// Intialize a new TracingMiddleware.
    ///
    /// - Parameters
    ///     - recordingHeaders: A list of HTTP header names to be recorded as span attributes. By default, no headers
    ///         are being recorded.
    ///     - parameters: A list of static parameters added to every span. These could be the "net.host.name",
    ///         "net.host.port" or "http.scheme"
    init(recordingHeaders headerNamesToRecord: some Collection<HTTPField.Name> = [], attributes: SpanAttributes? = nil) {
        self.headerNamesToRecord = Set(headerNamesToRecord.map(RecordingHeader.init))
        self.attributes = attributes
    }

    func handle(_ request: Request, context: BokRequestContext, next: (Request, BokRequestContext) async throws -> Response) async throws -> Response {
        var serviceContext = ServiceContext.current ?? ServiceContext.topLevel
        InstrumentationSystem.instrument.extract(request.headers, into: &serviceContext, using: HTTPHeadersExtractor())

        let operationName: String = {
            guard let endpointPath = context.endpointPath else {
                return "HTTP \(request.method.rawValue) route not found"
            }
            return "\(request.method.rawValue) \(endpointPath)"
        }()

        return try await InstrumentationSystem.tracer.withSpan(operationName, context: serviceContext, ofKind: .server) { span in
            span.updateAttributes { attributes in
                if let staticAttributes = self.attributes {
                    attributes.merge(staticAttributes)
                }
                attributes["http.method"] = request.method.rawValue
                attributes["http.target"] = request.uri.path
                // TODO: Get HTTP version and scheme
                // attributes["http.flavor"] = "\(request.version.major).\(request.version.minor)"
                // attributes["http.scheme"] = request.uri.scheme?.rawValue
                attributes["http.user_agent"] = request.headers[.userAgent]
                attributes["http.request_content_length"] = request.headers[.contentLength].map { Int($0) } ?? nil

                if let remoteAddress = (context as? any RemoteAddressRequestContext)?.remoteAddress {
                    attributes["net.sock.peer.port"] = remoteAddress.port

                    switch remoteAddress.protocol {
                    case .inet:
                        attributes["net.sock.peer.addr"] = remoteAddress.ipAddress
                    case .inet6:
                        attributes["net.sock.family"] = "inet6"
                        attributes["net.sock.peer.addr"] = remoteAddress.ipAddress
                    case .unix:
                        attributes["net.sock.family"] = "unix"
                        attributes["net.sock.peer.addr"] = remoteAddress.pathname
                    default:
                        break
                    }
                }
                attributes = recordHeaders(request.headers, toSpanAttributes: attributes, withPrefix: "http.request.header.")
            }

            // We put the span into the context so other middleware can update attributes
            var contextCopy = context
            contextCopy.span = span

            do {
                let response = try await next(request, contextCopy)
                span.updateAttributes { attributes in
                    attributes = recordHeaders(response.headers, toSpanAttributes: attributes, withPrefix: "http.response.header.")

                    attributes["http.status_code"] = Int(response.status.code)
                    attributes["http.response_content_length"] = response.body.contentLength
                }
                return response
            } catch let error as HTTPResponseError {
                span.attributes["http.status_code"] = Int(error.status.code)

                if 500 ..< 600 ~= error.status.code {
                    span.setStatus(.init(code: .error))
                }

                throw error
            }
        }
    }

    func recordHeaders(_ headers: HTTPFields, toSpanAttributes attributes: SpanAttributes, withPrefix prefix: String) -> SpanAttributes {
        var attributes = attributes
        for header in headerNamesToRecord {
            let values = headers[values: header.name]
            guard !values.isEmpty else {
                continue
            }
            let attribute = "\(prefix)\(header.attributeName)"

            if values.count == 1 {
                attributes[attribute] = values[0]
            } else {
                attributes[attribute] = values
            }
        }
        return attributes
    }
}

/// Protocol for request context that stores the remote address of connected client.
///
/// If you want the TracingMiddleware to record the remote address of requests
/// then your request context will need to conform to this protocol
protocol RemoteAddressRequestContext: BaseRequestContext {
    /// Connected host address
    var remoteAddress: SocketAddress? { get }
}

struct RecordingHeader: Hashable {
    let name: HTTPField.Name
    let attributeName: String

    init(name: HTTPField.Name) {
        self.name = name
        self.attributeName = name.canonicalName.replacingOccurrences(of: "-", with: "_")
    }
}

private struct HTTPHeadersExtractor: Extractor {
    func extract(key name: String, from headers: HTTPFields) -> String? {
        guard let headerName = HTTPField.Name(name) else {
            return nil
        }
        return headers[headerName]
    }
}

extension Span {
    /// Update Span attributes in a block instead of individually
    ///
    /// Updating a span attribute will involve some type of thread synchronisation
    /// primitive to avoid multiple threads updating the attributes at the same
    /// time. If you update each attributes individually this could cause slowdown.
    /// This function updates the attributes in one call to avoid hitting the
    /// thread synchronisation code multiple times
    ///
    /// - Parameter update: closure used to update span attributes
    func updateAttributes(_ update: (inout SpanAttributes) -> Void) {
        var attributes = attributes
        update(&attributes)
        self.attributes = attributes
    }
}
