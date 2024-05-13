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

import Foundation
import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve a list of Transactions for the specified Account of the authenticated user
    func registerListTransactions(storage: StorageService) {
        get("/accounts/:account/transactions") { _, context in
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
