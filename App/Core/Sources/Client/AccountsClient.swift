//===----------------------------------------------------------------------===//
//
// This source file is part of a technology demo for /dev/world 2024.
//
// Copyright © 2024 ANZ. All rights reserved.
// Licensed under the MIT license
//
// See LICENSE for license information
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import AsyncHTTPClient
import Models

public protocol AccountsClient: Sendable & Actor {

    /// Fetches the list of accounts for the current user
    func listAccounts() async throws -> [Account]

    /// Fetches the specified account
    func getAccount(id: Account.ID) async throws -> Account?

}

package actor DefaultAccountsClient {

    // MARK: - Properties

    let client: BokBankClient


    // MARK: - Initialisation

    package init(userID: User.ID, endpoint: Endpoint) {
        self.client = BokBankClient(endpoint: endpoint, user: userID)
    }

}


// MARK: - Accounts Client

extension DefaultAccountsClient: AccountsClient {

    package func listAccounts() async throws -> [Account] {
        try await client.get("/accounts")
    }

    package func getAccount(id: Account.ID) async throws -> Account? {
        try await client.get("/accounts/\(id)")
    }

}
