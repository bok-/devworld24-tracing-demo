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

public protocol TransactionsClient: Sendable & Actor {

    /// Fetches the list of transactions for the current user
    func listTransactions(account: Account.ID) async throws -> [Transaction]

    /// Fetches the specified transaction
    func getTransaction(id: Transaction.ID, account: Account.ID) async throws -> Transaction?

}

package actor DefaultTransactionsClient {

    // MARK: - Properties

    let client: BokBankClient


    // MARK: - Initialisation

    package init(userID: User.ID, endpoint: Endpoint) {
        self.client = BokBankClient(endpoint: endpoint, user: userID)
    }

}


// MARK: - Merchants Client

extension DefaultTransactionsClient: TransactionsClient {

    package func listTransactions(account: Account.ID) async throws -> [Transaction] {
        try await client.get("/accounts/\(account)/transactions")
    }

    package func getTransaction(id: Transaction.ID, account: Account.ID) async throws -> Transaction? {
        try await client.get("/accounts/\(account)/transactions/\(id)")
    }

}
