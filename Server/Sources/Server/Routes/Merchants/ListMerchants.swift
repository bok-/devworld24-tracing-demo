
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve a list of Merchants for the authenticated user
    func registerListMerchants(storage: StorageService) {
        get("/merchants") { request, context in
            try await storage.merchantsRepository
                .allMerchants(for: context.userID)
                .first()
            ?? []
        }
    }

}
