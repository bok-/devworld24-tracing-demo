
import Hummingbird
import Models

// These conformances are to allow us to be able to return raw model types
// as part of our API request handlers. No reason to wrap them in `Response`
// every time.

extension Account: ResponseEncodable {}
extension Merchant: ResponseEncodable {}
extension Transaction: ResponseEncodable {}
extension Transaction.TransferDetails: ResponseEncodable {}
extension Transaction.PaymentDetails: ResponseEncodable {}
