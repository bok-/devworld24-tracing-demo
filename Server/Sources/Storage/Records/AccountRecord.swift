
import GRDB
import Models
import OTel
import Tracing

/// A representation of an Account as persisted to the database
final class AccountRecord: Codable, PersistableRecord, FetchableRecord {

    // MARK: - Properties

    /// Primary key
    public let id: String

    /// Bank-State-Branch code
    public let bsb: String

    /// Main account number
    public let number: String

    /// Display name for the account
    public let name: String

    /// The type of product. eg transacting account or savings account
    public let product: Product

    /// Current amount of money held in the account
    public var balance: Money

    /// The source span that updated this model.
    /// This is used to associate spans where subscribers receive updated models with the trace that changed the model.
    public var updatedBy: OTelSpanContext?

    /// Our supported products
    enum Product: String, Codable {
        case transacting
        case savings
    }


    // MARK: - Initialisation

    /// Memberwise initialiser
    init(id: String, bsb: String, number: String, name: String, product: Product, balance: Money, updatedBy: OTelSpanContext?) {
        self.id = id
        self.bsb = bsb
        self.number = number
        self.name = name
        self.product = product
        self.balance = balance
        self.updatedBy = updatedBy
    }

}


// MARK: - TableRecord Conformance

extension AccountRecord {

    static var databaseTableName: String {
        "account"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let bsb = Column(CodingKeys.bsb)
        static let number = Column(CodingKeys.number)
        static let name = Column(CodingKeys.name)
        static let product = Column(CodingKeys.product)
        static let balance = Column(CodingKeys.balance)
        static let updatedBy = Column(CodingKeys.updatedBy)
    }

}


// MARK: - Bridging

extension Account {
    init(_ record: AccountRecord) {
        self.init(
            id: record.id,
            bsb: record.bsb,
            number: record.number,
            name: record.name,
            product: .init(record.product),
            balance: record.balance,
            updatedBy: record.updatedBy
        )
    }
}

extension AccountRecord {
    convenience init(_ account: Account) {
        self.init(
            id: account.id,
            bsb: account.bsb,
            number: account.number,
            name: account.name,
            product: .init(account.product),
            balance: account.balance,
            updatedBy: ServiceContext.current?.spanContext
        )
    }
}

extension Account.Product {
    init(_ product: AccountRecord.Product) {
        switch product {
        case .transacting:          self = .transacting
        case .savings:              self = .savings
        }
    }
}

extension AccountRecord.Product {
    init(_ product: Account.Product) {
        switch product {
        case .transacting:          self = .transacting
        case .savings:              self = .savings
        }
    }
}
