
import GRDB
import Models

final class CacheMerchantsRepository: Sendable {

    private let cache: CacheService

    init(cacheService: CacheService) {
        self.cache = cacheService
    }

}


// MARK: - Merchants Repository

public protocol MerchantsRepository {

    /// Returns an AsyncSequence that emits the list of the specified user's known merchants
    /// whenever they change.
    func allMerchants(for userID: User.ID) throws -> AsyncValueSequence<[Merchant]>

    /// Returns an AsyncSequence that emits the merchant for the identifier specified
    /// whenever it changes.
    func merchant(for userID: User.ID, merchant: Merchant.ID) throws -> AsyncValueSequence<Merchant?>

}

extension CacheMerchantsRepository: MerchantsRepository {

    func allMerchants(for userID: User.ID) throws -> AsyncValueSequence<[Merchant]> {
        try cache.observing { db in
            try MerchantRecord.fetchAll(db)
                .map(Merchant.init)
        }
    }

    func merchant(for userID: User.ID, merchant: Merchant.ID) throws -> AsyncValueSequence<Merchant?> {
        try cache.observing { db in
            try MerchantRecord.fetchOne(db, key: merchant)
                .map(Merchant.init)
        }
    }

}


// MARK: - Storage Access

public extension CacheService {
    var merchantsRepository: MerchantsRepository {
        CacheMerchantsRepository(cacheService: self)
    }
}
