
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve a list of Account for the authenticated user
    func registerListAccounts(storage: StorageService) {
        get("/accounts") { request, context in
            try await storage.accountsRepository
                .allAccounts(for: context.userID)
                .first()
            ?? []
        }
    }

}
