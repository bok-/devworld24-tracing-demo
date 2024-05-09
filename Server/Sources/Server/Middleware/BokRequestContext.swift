
import Hummingbird
import HummingbirdWebSocket
import Logging
import Models
import NIOCore
import Tracing

/// A Hummingbird request context that includes the user authenticated by the ``AuthenticationMiddleware``
/// as well as standard request and WebSocket information.
struct BokRequestContext: WebSocketRequestContext {

    // MARK: - Properties

    /// The authenticated user
    var userID: User.ID!            // TODO: Error handling

    /// The request span so that other middleware or the request handler can add span attributes
    var span: Span?


    // MARK: - WebSocketRequestContext Conformance

    var coreContext: CoreRequestContext
    var additionalData: String?
    var webSocket: WebSocketHandlerReference<BokRequestContext>

    init(channel: Channel, logger: Logger) {
        self.coreContext = .init(allocator: channel.allocator, logger: logger)
        self.additionalData = nil
        self.webSocket = .init()
    }

}
