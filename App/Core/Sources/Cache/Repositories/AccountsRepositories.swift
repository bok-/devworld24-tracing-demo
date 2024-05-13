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

import GRDB
import Models

final class CacheAccountsRepository: Sendable {

    private let cache: CacheService

    init(cacheService: CacheService) {
        self.cache = cacheService
    }

}


// MARK: - Accounts Repository

public protocol AccountsRepository {

    /// Returns an AsyncSequence that emits the list of the specified user's accounts
    /// whenever they change.
    func allAccounts(for userID: User.ID) throws -> AsyncValueSequence<[Account]>

    /// Returns an AsyncSequence that emits the account for the identifier specified
    /// whenever it changes.
    func account(for userID: User.ID, account: Account.ID) throws -> AsyncValueSequence<Account?>

}

extension CacheAccountsRepository: AccountsRepository {

    public func allAccounts(for userID: User.ID) throws -> AsyncValueSequence<[Account]> {
        try cache.observing { db in
            try AccountRecord.fetchAll(db)
                .map(Account.init)
        }
    }

    func account(for userID: User.ID, account: Account.ID) throws -> AsyncValueSequence<Account?> {
        try cache.observing { db in
            try AccountRecord.fetchOne(db, key: account)
                .map(Account.init)
        }
    }

}


// MARK: - Cache Access

public extension CacheService {
    var accountsRepository: AccountsRepository {
        CacheAccountsRepository(cacheService: self)
    }
}
