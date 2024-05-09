
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve the specified Account for the authenticated user
    func registerGetAccount(storage: StorageService) {
        get("/accounts/:account") { request, context in
            guard
                let accountID = context.parameters.get("account"),
                let account = try await storage.accountsRepository.account(for: context.userID, account: accountID).first()
            else {
                throw HTTPError(.notFound)
            }

            return account
        }
    }

}
