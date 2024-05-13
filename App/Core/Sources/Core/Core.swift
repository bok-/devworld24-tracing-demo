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

import Cache
import Client
import Foundation
import Logging
import Models
import NIOPosix
import NIOTransportServices
import os
import OTel
import OTLPGRPC
import Tracing

public final class AppCore: Sendable, ObservableObject {

    // MARK: - Properties

    public let userID: User.ID
    public let endpoint: Endpoint


    // MARK: - Services

    public let cacheService: CacheService
    public let tracer: any TracerServiceLifecycle

    public let tracingTask = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)


    // MARK: - Repositories

    public var accountsRepository: AccountsRepository {
        cacheService.accountsRepository
    }

    public var merchantsRepository: MerchantsRepository {
        cacheService.merchantsRepository
    }

    public var transactionsRepository: TransactionsRepository {
        cacheService.transactionsRepository
    }


    // MARK: - API Clients

    // We keep this as a stored property so the sync can keep running
    public let syncClient: SyncClient

    public var accountsClient: AccountsClient {
        DefaultAccountsClient(userID: userID, endpoint: endpoint)
    }

    public var merchantsClient: MerchantsClient {
        DefaultMerchantsClient(userID: userID, endpoint: endpoint)
    }

    public var paymentsClient: PaymentsClient {
        DefaultPaymentsClient(userID: userID, endpoint: endpoint)
    }

    public var transactionsClient: TransactionsClient {
        DefaultTransactionsClient(userID: userID, endpoint: endpoint)
    }


    // MARK: - Initialisation

    public init(userID: User.ID, endpoint: Endpoint) throws {
        self.userID = userID
        self.endpoint = endpoint
        self.cacheService = try CacheService(userID: userID)
        self.syncClient = DefaultSyncClient(userID: userID, endpoint: endpoint, cache: cacheService)
        self.tracer = try Self.bootstrapTelemetry()
    }


    // MARK: - Sync Control

    public func startSync() async {
        tracingTask.withLock {
            $0 = Task.detached { [tracer] in
                do {
                    try await tracer.run()
                } catch {
                    print("Error running tracer: \(error)")
                }
            }
        }
        await syncClient.start()
    }

    public func cancelSync() async {
        await syncClient.cancel()
        tracingTask.withLock {
            $0?.cancel()
            $0 = nil
        }
    }


    // MARK: - Telemetry

    private static func bootstrapTelemetry() throws -> any TracerServiceLifecycle {
        LoggingSystem.bootstrap({
            let logger = StreamLogHandler.standardOutput(label: $0, metadataProvider: $1)
            // Uncomment this to enable debug logging
            // logger.logLevel = .debug
            return logger
        }, metadataProvider: .otel())

        let exporter = try OTLPGRPCSpanExporter(
            configuration: .init(
                environment: .detected(),
                shouldUseAnInsecureConnection: true
            ),
            group: NIOTSEventLoopGroup.singleton,
            requestLogger: Logger(label: "export-request"),
            backgroundActivityLogger: Logger(label: "export-background")
        )
        let processor = OTelSimpleSpanProcessor(exporter: exporter)

        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelConstantSampler(isOn: true),
            propagator: OTelW3CPropagator(),
            processor: processor,
            environment: .detected(),
            resource: .init(attributes: [
                "service.name": "bokbank.app",
            ])
        )

        InstrumentationSystem.bootstrap(tracer)
        return tracer
    }

}

public protocol TracerServiceLifecycle: Tracer {
    func run() async throws
}

extension OTelTracer: TracerServiceLifecycle {}
