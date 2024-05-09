
import GRDB
import Models

final class StorageTransactionsRepository: Sendable {

    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }

}


// MARK: - Transactions Repository

/// Access to the local Transactions database
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

extension StorageTransactionsRepository: TransactionsRepository {

    func allTransactions(for userID: User.ID) throws -> AsyncValueSequence<[Transaction]> {
        try storage.observing(partition: userID) { db in
            try TransactionRecord.fetchAll(db)
                .map(Transaction.init)
        }
    }

    func transactions(for userID: User.ID, account: Account.ID) throws -> AsyncValueSequence<[Transaction]> {
        try storage.observing(partition: userID) { db in
            try TransactionRecord
                .filter(TransactionRecord.Columns.accountID == account)
                .fetchAll(db)
                .map(Transaction.init)
        }
    }

    func transaction(for userID: User.ID, transaction: Transaction.ID) throws -> AsyncValueSequence<Transaction?> {
        try storage.observing(partition: userID) { db in
            try TransactionRecord
                .fetchOne(db, key: transaction)
                .map(Transaction.init)
        }
    }

}


// MARK: - Storage Access

public extension StorageService {
    var transactionsRepository: TransactionsRepository {
        StorageTransactionsRepository(storage: self)
    }
}
