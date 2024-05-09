
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve the specified Merchant for the authenticated user
    func registerGetMerchant(storage: StorageService) {
        get("/merchants/:merchant") { request, context in
            guard
                let merchantID = context.parameters.get("merchant"),
                let merchant = try await storage.merchantsRepository.merchant(for: context.userID, merchant: merchantID).first()
            else {
                throw HTTPError(.notFound)
            }

            return merchant
        }
    }

}
