
import Foundation
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve a list of Transactions for the specified Account of the authenticated user
    func registerListTransactions(storage: StorageService) {
        get("/accounts/:account/transactions") { request, context in
            guard
                let accountID = context.parameters.get("account")?.removingPercentEncoding,
                try await storage.accountsRepository.account(for: context.userID, account: accountID).first() != nil
            else {
                throw HTTPError(.notFound)
            }
            
            return try await storage.transactionsRepository
                .transactions(for: context.userID, account: accountID)
                .first()
            ?? []
        }
    }

}
