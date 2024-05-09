
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to allow the user to make a transfer between their Accounts
    func registerTransfer(storage: StorageService) {
        post("/transfer") { request, context in
            do {
                let transfer = try await request.decode(as: TransferRequest.self, context: context)
                try await FraudChecker().check(transfer: transfer)
                return try await storage.paymentsRepository.transfer(
                    userID: context.userID,
                    from: transfer.fromAccount,
                    to: transfer.toAccount,
                    amount: transfer.amount
                )
            } catch let error as PaymentError {
                throw HTTPError(400, message: error.errorDescription)
            }
        }
    }

}
