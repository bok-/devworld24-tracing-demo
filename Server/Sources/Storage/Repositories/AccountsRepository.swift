
import GRDB
import Models

final class StorageAccountsRepository: Sendable {

    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }

}


// MARK: - Accounts Repository

/// Access to the local Accounts database
public protocol AccountsRepository {

    /// Returns an AsyncSequence that emits the list of the specified user's accounts
    /// whenever they change.
    func allAccounts(for userID: User.ID) throws -> AsyncValueSequence<[Account]>

    /// Returns an AsyncSequence that emits the account for the identifier specified
    /// whenever it changes.
    func account(for userID: User.ID, account: Account.ID) throws -> AsyncValueSequence<Account?>

}

extension StorageAccountsRepository: AccountsRepository {

    public func allAccounts(for userID: User.ID) throws -> AsyncValueSequence<[Account]> {
        try storage.observing(partition: userID) { db in
            try AccountRecord.fetchAll(db)
                .map(Account.init)
        }
    }

    func account(for userID: User.ID, account: Account.ID) throws -> AsyncValueSequence<Account?> {
        try storage.observing(partition: userID) { db in
            try AccountRecord.fetchOne(db, key: account)
                .map(Account.init)
        }
    }

}


// MARK: - Storage Access

public extension StorageService {
    var accountsRepository: AccountsRepository {
        StorageAccountsRepository(storage: self)
    }
}
