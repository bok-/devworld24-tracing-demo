
import GRDB
import Models

final class StorageMerchantsRepository: Sendable {

    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }

}


// MARK: - Merchants Repository

/// Access to the local Merchants database
public protocol MerchantsRepository {

    /// Returns an AsyncSequence that emits the list of the specified user's known merchants
    /// whenever they change.
    func allMerchants(for userID: User.ID) throws -> AsyncValueSequence<[Merchant]>

    /// Returns an AsyncSequence that emits the merchant for the identifier specified
    /// whenever it changes.
    func merchant(for userID: User.ID, merchant: Merchant.ID) throws -> AsyncValueSequence<Merchant?>

}

extension StorageMerchantsRepository: MerchantsRepository {

    func allMerchants(for userID: User.ID) throws -> AsyncValueSequence<[Merchant]> {
        try storage.observing(partition: userID) { db in
            try MerchantRecord.fetchAll(db)
                .map(Merchant.init)
        }
    }

    func merchant(for userID: User.ID, merchant: Merchant.ID) throws -> AsyncValueSequence<Merchant?> {
        try storage.observing(partition: userID) { db in
            try MerchantRecord.fetchOne(db, key: merchant)
                .map(Merchant.init)
        }
    }

}


// MARK: - Storage Access

public extension StorageService {
    var merchantsRepository: MerchantsRepository {
        StorageMerchantsRepository(storage: self)
    }
}
