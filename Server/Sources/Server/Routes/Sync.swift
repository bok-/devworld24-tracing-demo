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

import AsyncAlgorithms
import Hummingbird
import HummingbirdWebSocket
import Models
import OTel
import Storage
import Tracing
import TracingOpenTelemetrySemanticConventions

extension Router<BokRequestContext> {

    /// Registers the route to handle upgrading of /sync requests to a WebSocket, and then handle the WebSocket
    /// request to subscribe and sync any database changes.
    func registerSync(storage: StorageService) {
        ws("/sync") { _, writer, context in

            // We run this as a detached task because we can't use tracing here at all. It
            // throws task-local modification assertions because somewhere inside NIO or
            // Hummingbird we are inside a `withTaskGroup` call, but not inside the `group.addTask`.

            let task = Task.detached {

                // Hummingbird middleware doesn't do tracing for WebSocket requests so we do that manually.
                try await withSpan("WS /sync") { span in
                    span.updateAttributes { attributes in
                        attributes.http.method = "WebSocket"
                        attributes.http.target = "/sync"
                    }

                    // Get a list of all of our database objects
                    let userID = context.requestContext.userID!
                    let values = try combineLatest(
                        storage.accountsRepository.allAccounts(for: userID),
                        storage.merchantsRepository.allMerchants(for: userID),
                        storage.transactionsRepository.allTransactions(for: userID)
                    )

                    var previousAccounts = [Account]()
                    var previousMerchants = [Merchant]()
                    var previousTransactions = [Transaction]()

                    // Iterate over database changes, compare them to our previously sent models and send the diffs
                    for try await (accounts, merchants, transactions) in values {

                        // Send account changes
                        for diff in accounts.identifiedDifference(from: previousAccounts) {
                            switch diff {
                            case let .inserted(account), let .changed(account):
                                try await withSpan("Sending Account", source: account.updatedBy, ofKind: .producer) { span in
                                    span.attributes["account.id"] = account.id

                                    let message = SyncMessage.account(account, source: span.context.spanContext)
                                    try await writer.write(message, context: context)
                                }

                            case let .removed(account):
                                try await withSpan("Deleting Account", ofKind: .producer) { span in
                                    span.attributes["account.id"] = account.id

                                    let message = SyncMessage.deleteAccount(account.id, source: span.context.spanContext)
                                    try await writer.write(message, context: context)
                                }
                            }
                        }
                        previousAccounts = accounts

                        // Send merchant changes
                        for diff in merchants.identifiedDifference(from: previousMerchants) {
                            switch diff {
                            case let .inserted(merchant), let .changed(merchant):
                                try await withSpan("Sending Merchant", source: merchant.updatedBy, ofKind: .producer) { span in
                                    span.attributes["merchant.id"] = merchant.id

                                    let message = SyncMessage.merchant(merchant, source: span.context.spanContext)
                                    try await writer.write(message, context: context)
                                }
                            case let .removed(merchant):
                                try await withSpan("Deleting Merchant", ofKind: .producer) { span in
                                    span.attributes["merchant.id"] = merchant.id

                                    let message = SyncMessage.deleteMerchant(merchant.id, source: span.context.spanContext)
                                    try await writer.write(message, context: context)
                                }
                            }
                        }
                        previousMerchants = merchants

                        // Send transaction changes
                        for diff in transactions.identifiedDifference(from: previousTransactions) {
                            switch diff {
                            case let .inserted(transaction), let .changed(transaction):
                                try await withSpan("Sending Transaction", source: transaction.updatedBy, ofKind: .producer) { span in
                                    span.attributes["transaction.id"] = transaction.id

                                    let message = SyncMessage.transaction(transaction, source: span.context.spanContext)
                                    try await writer.write(message, context: context)
                                }
                            case let .removed(transaction):
                                try await withSpan("Deleting Transaction", ofKind: .producer) { span in
                                    span.attributes["transaction.id"] = transaction.id

                                    let message = SyncMessage.deleteTransaction(transaction.id, source: span.context.spanContext)
                                    try await writer.write(message, context: context)
                                }
                            }
                        }
                        previousTransactions = transactions

                    }
                }
            }

            // Wait for the result of the detached task and cancel it if we're cancelled.
            try await withTaskCancellationHandler {
                _ = try await task.value
            } onCancel: {
                task.cancel()
            }

        }
    }

}

extension WebSocketOutboundWriter: ResponseBodyWriter {

    /// Writes the specified Encodable type to the WebSocket using the default response encoder (typically JSONEncoder)
    func write(_ response: some Encodable, context: WebSocketContextFromRouter<BokRequestContext>) async throws {
        let response = try context.requestContext.responseEncoder.encode(
            response,
            from: context.request,
            context: context.requestContext
        )
        _ = try await response.body.write(self)
    }

    /// Writes the specified ByteBuffer as a binary message on the WebSocket
    public func write(_ buffer: ByteBuffer) async throws {
        try await write(.binary(buffer))
    }

}


// MARK: - Tracing Helpers

/// A convenience wrapper for `withSpan` that makes it a child of the specified source context
private func withSpan<T>(
    _ operationName: String,
    source: OTelSpanContext?,
    ofKind: SpanKind = .producer,
    _ operation: @escaping (any Span) async throws -> T
) async rethrows -> T {
    // We need to run this in a detached task as attempting to mutate task-local values
    // like ServiceContext.current inside a TaskGroup (like the one Hummingbird is using
    // to process WebSocket messages) is invalid and throws assertions.

    let current = ServiceContext.current

    // If we have it reset the current context to be remote one and leave a link to the ingestion task
    var newContext: ServiceContext?
    if let source {
        var context = ServiceContext.topLevel
        InstrumentationSystem.instrument.extract(source, into: &context, using: BokSpanContextExtractor())
        newContext = context
    }

    return try await withSpan(operationName, context: newContext ?? current ?? .topLevel, ofKind: ofKind) { span in
        if let current, newContext == nil {
            span.addLink(.init(context: current, attributes: [:]))
        }
        return try await operation(span)
    }

}

/// Pretends to extract a W3C Trace Context `traceparent` conforming string from the given `OTelSpanContext`
private struct BokSpanContextExtractor: Extractor {
    typealias Carrier = OTelSpanContext?

    func extract(key: String, from carrier: Carrier) -> String? {
        guard key == "traceparent" else {
            return nil
        }
        return carrier?.traceparent
    }
}
