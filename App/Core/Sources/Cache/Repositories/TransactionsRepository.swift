
import GRDB
import Models

final class CacheTransactionsRepository: Sendable {

    private let cache: CacheService

    init(cacheService: CacheService) {
        self.cache = cacheService
    }

}


// MARK: - Transactions Repository

public protocol TransactionsRepository {

    /// Returns an AsyncSequence that emits the list of the specified user's transactions
    /// whenever they change.
    func allTransactions(for userID: User.ID) throws -> AsyncValueSequence<[Transaction]>

    /// Returns an AsyncSequence that emits the list of the specified user's transactions
    /// in the given account/
    func transactions(for userID: User.ID, account: Account.ID) throws -> AsyncValueSequence<[Transaction]>

    /// Returns an AsyncSequence that emits the transaction for the identifier specified
    /// whenever it changes.
    func transaction(for userID: User.ID, transaction: Transaction.ID) throws -> AsyncValueSequence<Transaction?>

}

extension CacheTransactionsRepository: TransactionsRepository {

    func allTransactions(for userID: User.ID) throws -> AsyncValueSequence<[Transaction]> {
        try cache.observing { db in
            try TransactionRecord.all()
                .order(TransactionRecord.Columns.instant.desc)
                .fetchAll(db)
                .map(Transaction.init)
        }
    }

    func transactions(for userID: User.ID, account: Account.ID) throws -> AsyncValueSequence<[Transaction]> {
        try cache.observing { db in
            try TransactionRecord
                .filter(TransactionRecord.Columns.accountID == account)
                .order(TransactionRecord.Columns.instant.desc)
                .fetchAll(db)
                .map(Transaction.init)
        }
    }

    func transaction(for userID: User.ID, transaction: Transaction.ID) throws -> AsyncValueSequence<Transaction?> {
        try cache.observing { db in
            try TransactionRecord
                .fetchOne(db, key: transaction)
                .map(Transaction.init)
        }
    }

}


// MARK: - Storage Access

public extension CacheService {
    var transactionsRepository: TransactionsRepository {
        CacheTransactionsRepository(cacheService: self)
    }
}
