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

public protocol PaymentsClient: Sendable & Actor {

    /// Makes an internal transfer
    func transfer(from source: Account, to target: Account, amount: Money) async throws -> Transaction.TransferDetails

}

package actor DefaultPaymentsClient {

    // MARK: - Properties

    let client: BokBankClient


    // MARK: - Initialisation

    package init(userID: User.ID, endpoint: Endpoint) {
        self.client = BokBankClient(endpoint: endpoint, user: userID)
    }

}


// MARK: - Payments Client

extension DefaultPaymentsClient: PaymentsClient {

    package func transfer(from source: Account, to target: Account, amount: Money) async throws -> Transaction.TransferDetails {
        let request = TransferRequest(fromAccount: source.id, toAccount: target.id, amount: amount)
        return try await client.post("/transfer", request: request)
    }

}
