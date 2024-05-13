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

import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve the specified Account for the authenticated user
    func registerGetAccount(storage: StorageService) {
        get("/accounts/:account") { _, context in
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
