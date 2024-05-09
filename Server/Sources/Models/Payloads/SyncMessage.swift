
import OTel

/// A message/instruction sent over the /sync WebSocket
///
/// The `source` associated value for each of these messages indicates
/// the span that triggered the change, if any.
///
public enum SyncMessage: Codable {

    /// An account was added or updated
    case account(Account, source: OTelSpanContext?)

    /// A merchant was added or updated
    case merchant(Merchant, source: OTelSpanContext?)

    /// A transaction was added or updated
    case transaction(Transaction, source: OTelSpanContext?)

    /// An account was deleted
    case deleteAccount(Account.ID, source: OTelSpanContext?)

    /// A merchant was deleted
    case deleteMerchant(Merchant.ID, source: OTelSpanContext?)

    /// A transaction was deleted
    case deleteTransaction(Transaction.ID, source: OTelSpanContext?)

}
