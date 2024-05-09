
import AsyncHTTPClient
import Models

public protocol MerchantsClient: Sendable & Actor {

    /// Fetches the list of merchants for the current user
    func listMerchants() async throws -> [Merchant]

    /// Fetches the specified merchant
    func getMerchant(id: Merchant.ID) async throws -> Merchant?

}

package actor DefaultMerchantsClient {

    // MARK: - Properties

    let client: BokBankClient


    // MARK: - Initialisation

    package init(userID: User.ID, endpoint: Endpoint) {
        self.client = BokBankClient(endpoint: endpoint, user: userID)
    }

}


// MARK: - Merchants Client

extension DefaultMerchantsClient: MerchantsClient {

    package func listMerchants() async throws -> [Merchant] {
        try await client.get("/merchants")
    }

    package func getMerchant(id: Merchant.ID) async throws -> Merchant? {
        try await client.get("/merchants/\(id)")
    }

}
