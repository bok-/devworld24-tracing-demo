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
import Cache
import Models
import OTel
import Tracing

public protocol SyncClient: Sendable & Actor {

    /// Starts a sync
    func start()

    /// Cancels an active sync
    func cancel()

}

package actor DefaultSyncClient {

    // MARK: - Properties

    let client: BokBankClient
    let cache: CacheService
    var task: Task<Void, Error>?


    // MARK: - Initialisation

    package init(userID: User.ID, endpoint: Endpoint, cache: CacheService) {
        self.client = BokBankClient(endpoint: endpoint, user: userID)
        self.cache = cache
    }

    deinit {
        task?.cancel()
    }

}


// MARK: - Sync Client

extension DefaultSyncClient: SyncClient {

    package func start() {
        task = Task.detached { [cache, client] in
            do {
                try await withSpan("WS /sync", ofKind: .client) { _ in
                    try await client.connect("/sync") { [cache] (message: SyncMessage) in
                        switch message {
                        case let .account(account, source):
                            try await withDetachedSpan("Received Account", source: source) { span in
                                span.updateAttributes {
                                    $0["account.id"] = account.id
                                }
                                try await cache.write {
                                    try AccountRecord(account).save($0)
                                }
                            }

                        case let .merchant(merchant, source):
                            try await withDetachedSpan("Received Merchant", source: source) { span in
                                span.updateAttributes {
                                    $0["merchant.id"] = merchant.id
                                }
                                try await cache.write {
                                    try MerchantRecord(merchant).save($0)
                                }
                            }

                        case let .transaction(transaction, source):
                            try await withDetachedSpan("Received Transaction", source: source) { span in
                                span.updateAttributes {
                                    $0["transaction.id"] = transaction.id
                                }
                                try await cache.write {
                                    try TransactionRecord(transaction).save($0)
                                }
                            }

                        case let .deleteAccount(id, source):
                            try await withDetachedSpan("Deleted Account", source: source) { span in
                                span.updateAttributes {
                                    $0["account.id"] = id
                                }
                                try await cache.write {
                                    _ = try AccountRecord.deleteOne($0, key: id)
                                }
                            }

                        case let .deleteMerchant(id, source):
                            try await withDetachedSpan("Deleted Merchant", source: source) { span in
                                span.updateAttributes {
                                    $0["merchant.id"] = id
                                }
                                try await cache.write {
                                    _ = try MerchantRecord.deleteOne($0, key: id)
                                }
                            }

                        case let .deleteTransaction(id, source):
                            try await withDetachedSpan("Deleted Transaction", source: source) { span in
                                span.updateAttributes {
                                    $0["transaction.id"] = id
                                }
                                try await cache.write {
                                    _ = try TransactionRecord.deleteOne($0, key: id)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Caught error on websocket: \(error)")
            }
        }
    }

    package func cancel() {
        task?.cancel()
    }

}

private func withDetachedSpan<T>(
    _ operationName: String,
    source: OTelSpanContext?,
    _ operation: @escaping (any Span) async throws -> T
) async rethrows -> T {
    // We need to run this in a detached task as attempting to mutate task-local values
    // like ServiceContext.current inside a TaskGroup (like the one Hummingbird is using
    // to process WebSocket messages) is invalid and throws assertions.

    let task = Task.detached {

        let current = ServiceContext.current

        // If we have it reset the current context to be remote one and leave a link to the ingestion task
        var context = ServiceContext.topLevel
        if let source {
            InstrumentationSystem.instrument.extract(source, into: &context, using: BokSpanContextExtractor())
        }

        return try await withSpan(operationName, context: context, ofKind: .consumer) { span in
            if let current {
                span.addLink(.init(context: current, attributes: [:]))
            }
            return try await operation(span)
        }
    }

    return try await withTaskCancellationHandler {
        try await task.value
    } onCancel: {
        task.cancel()
    }

}

// This assumes W3C Propagation
private struct BokSpanContextExtractor: Extractor {
    typealias Carrier = OTelSpanContext?

    func extract(key: String, from carrier: Carrier) -> String? {
        guard key == "traceparent" else {
            return nil
        }
        return carrier?.traceparent
    }
}
