
import Models
import Tracing

/// Our magical unicorn fraud checker
struct FraudChecker {

    /// Checks a transfer for fraud
    func check(transfer: TransferRequest) async throws {
        try await withSpan("Check Fraud") { _ in
            // TODO: Actually check for fraud.
            // For now lets simulate hitting an API
            try await withSpan("/check", ofKind: .client) { span in
                span.updateAttributes { attributes in
                    attributes["url.full"] = "https://magic.fraudchecking.com/check"
                    attributes["http.request.method"] = "POST"
                    attributes["server.address"] = "127.0.0.1"
                    attributes["server.port"] = "443"
                    attributes["url.path"] = "/check"
                    attributes["url.scheme"] = "https"
                    attributes["http.response.status_code"] = 200
                }

                // Include a delay to set the users' expectations about how long transfers take
                try await ContinuousClock().sleep(for: .milliseconds(300))
            }
        }
    }

}
