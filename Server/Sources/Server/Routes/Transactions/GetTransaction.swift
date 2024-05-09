
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve the specified Transaction on the specified Account for the authenticated user
    func registerGetTransaction(storage: StorageService) {
        get("/accounts/:account/transactions/:transaction") { request, context in
            guard
                let accountID = context.parameters.get("account")?.removingPercentEncoding,
                try await storage.accountsRepository.account(for: context.userID, account: accountID).first() != nil,
                let transactionID = context.parameters.get("transaction"),
                let transaction = try await storage.transactionsRepository.transaction(for: context.userID, transaction: transactionID).first()
            else {
                throw HTTPError(.notFound)
            }

            return transaction
        }
    }

}
