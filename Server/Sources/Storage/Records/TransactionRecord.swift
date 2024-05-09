
import GRDB
import Foundation
import Models
import OTel
import Tracing

final class TransactionRecord: Codable, PersistableRecord, FetchableRecord {

    // MARK: - Properties

    /// Primary key
    public let id: String

    /// The Account that the transaction applies to
    public let accountID: String

    /// The date/time that the transaction occurred
    public let instant: Date

    /// The amount of Money involved
    public let amount: Money

    /// A free-form text description of the transaction. Used when we can't display an enriched description
    public let description: String

    /// The category of the transaction. eg Transfer, Payment, Groceries, Eating and Drinking Out
    public let category: String

    /// More specific details depending on the type of transaction, eg card details, payment details, etc
    public let details: Details

    /// The source span that updated this model.
    /// This is used to associate spans where subscribers receive updated models with the trace that changed the model.
    public let updatedBy: OTelSpanContext?

    /// More specific details depending on the type of transaction, eg card details, payment details, etc
    enum Details: Codable {
        case card(merchantID: String)
        case payment(fromAccount: String, toAccount: String, receiptNumber: String)
        case transfer(fromAccount: String, toAccount: String, receiptNumber: String)
    }


    // MARK: - Initialisation

    /// Memberwise initialiser
    init(
        id: String,
        accountID: String,
        instant: Date,
        amount: Money,
        description: String,
        category: String,
        details: Details,
        updatedBy: OTelSpanContext?
    ) {
        self.id = id
        self.accountID = accountID
        self.instant = instant
        self.amount = amount
        self.description = description
        self.category = category
        self.details = details
        self.updatedBy = updatedBy
    }

}


// MARK: - TableRecord Conformance

extension TransactionRecord {

    static var databaseTableName: String {
        "transaction"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let accountID = Column(CodingKeys.accountID)
        static let instant = Column(CodingKeys.instant)
        static let amount = Column(CodingKeys.amount)
        static let description = Column(CodingKeys.description)
        static let category = Column(CodingKeys.category)
        static let details = Column(CodingKeys.details)
        static let updatedBy = Column(CodingKeys.updatedBy)
    }

}


// MARK: - Bridging

extension Transaction {
    init(_ record: TransactionRecord) {
        switch record.details {
        case let .card(merchantID):
            self.init(
                id: record.id,
                accountID: record.accountID,
                instant: record.instant,
                cardDetails: .init(merchantID: merchantID),
                amount: record.amount,
                category: record.category,
                description: record.description,
                updatedBy: record.updatedBy
            )

        case let .payment(fromAccount, toAccount, receiptNumber):
            self.init(
                id: record.id,
                accountID: record.accountID,
                instant: record.instant,
                paymentDetails: .init(fromAccount: fromAccount, toAccount: toAccount, receiptNumber: receiptNumber),
                amount: record.amount,
                category: record.category,
                description: record.description,
                updatedBy: record.updatedBy
            )

        case let .transfer(fromAccount, toAccount, receiptNumber):
            self.init(
                id: record.id,
                accountID: record.accountID,
                instant: record.instant,
                transferDetails: .init(fromAccount: fromAccount, toAccount: toAccount, receiptNumber: receiptNumber),
                amount: record.amount,
                category: record.category,
                description: record.description,
                updatedBy: record.updatedBy
            )
        }
    }
}
