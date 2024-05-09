
import GRDB
import Models

public final class AccountRecord: Codable, PersistableRecord, FetchableRecord {

    // MARK: - Properties

    let id: String
    let bsb: String
    let number: String
    let name: String
    let product: Product
    var balance: Money

    enum Product: String, Codable {
        case transacting
        case savings
    }


    // MARK: - Initialisation

    /// Memberwise initialiser
    init(id: String, bsb: String, number: String, name: String, product: Product, balance: Money) {
        self.id = id
        self.bsb = bsb
        self.number = number
        self.name = name
        self.product = product
        self.balance = balance
    }

}


// MARK: - TableRecord Conformance

extension AccountRecord {

    public static var databaseTableName: String {
        "account"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let bsb = Column(CodingKeys.bsb)
        static let number = Column(CodingKeys.number)
        static let name = Column(CodingKeys.name)
        static let balance = Column(CodingKeys.balance)
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
            updatedBy: nil
        )
    }
}

public extension AccountRecord {
    convenience init(_ account: Account) {
        self.init(
            id: account.id,
            bsb: account.bsb,
            number: account.number,
            name: account.name,
            product: .init(account.product),
            balance: account.balance
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
