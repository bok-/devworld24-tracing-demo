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

import Dispatch
import Foundation
import GRDB
import Models
import Tracing

/// Main class for cache access.
public final class CacheService: Sendable {

    // MARK: - Properties

    private let database: DatabasePool


    // MARK: - Initialisation and Creation

    public init(userID: User.ID) throws {
        self.database = try withSpan("Open Database") { span in
            span.updateAttributes { attributes in
                attributes.db.system = "sqlite"
                attributes.db.name = "db"
            }

            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let pool = try DatabasePool(
                path: "\(documentsDir)/Cache-\(userID).sqlite",
                configuration: {
                    var configuration = Configuration()
                    configuration.prepareDatabase { db in
                        db.trace(options: .profile, makeGRDBTraceFunction())
                    }
                    return configuration
                }()
            )

            // Migrations
            var migrator = DatabaseMigrator()
            for migration in Migrations.allMigrations {
                migrator.registerMigration(migration.0, migrate: migration.1)
            }
            try migrator.migrate(pool)

            return pool
        }
    }


    // MARK: - Database Access

    /// Executes read-only database operations, and returns their result after
    /// they have finished executing.
    ///
    /// For example:
    ///
    /// ```swift
    /// let count = try reader.read { db in
    ///     try Player.fetchCount(db)
    /// }
    /// ```
    ///
    /// Database operations are isolated in a transaction: they do not see
    /// changes performed by eventual concurrent writes (even writes performed
    /// by other processes).
    ///
    /// The database connection is read-only: attempts to write throw a
    /// ``DatabaseError`` with resultCode `SQLITE_READONLY`.
    ///
    /// The ``Database`` argument to `value` is valid only during the execution
    /// of the closure. Do not store or return the database connection for
    /// later use.
    ///
    /// It is a programmer error to call this method from another database
    /// access method. Doing so raises a "Database methods are not reentrant"
    /// fatal error at runtime.
    ///
    /// - parameter value: A closure which accesses the database.
    /// - throws: The error thrown by `value`, or any ``DatabaseError`` that
    ///   would happen while establishing the database access.
    ///
    package func read<T>(_ value: @Sendable @escaping (Database) throws  -> T) async throws -> T {
        let span = ServiceContext.current
        return try await database.read { db in
            try ServiceContext.$current.withValue(span) {
                try value(db)
            }
        }
    }

    /// Executes database operations, and returns their result after they have
    /// finished executing.
    ///
    /// For example:
    ///
    /// ```swift
    /// let newPlayerCount = try writer.write { db in
    ///     try Player(name: "Arthur").insert(db)
    ///     return try Player.fetchCount(db)
    /// }
    /// ```
    ///
    /// Database operations are wrapped in a transaction. If they throw an
    /// error, the transaction is rollbacked and the error is rethrown.
    ///
    /// Concurrent database accesses can not see partial database updates (even
    /// when performed by other processes).
    ///
    /// Database operations run in the writer dispatch queue, serialized
    /// with all database updates performed by this `DatabaseWriter`.
    ///
    /// The ``Database`` argument to `updates` is valid only during the
    /// execution of the closure. Do not store or return the database connection
    /// for later use.
    ///
    /// It is a programmer error to call this method from another database
    /// access method. Doing so raises a "Database methods are not reentrant"
    /// fatal error at runtime.
    ///
    /// - parameter updates: A closure which accesses the database.
    /// - throws: The error thrown by `updates`, or any ``DatabaseError`` that
    ///   would happen while establishing the database access or committing
    ///   the transaction.
    ///
    package func write<T>(_ updates: @Sendable @escaping (Database) throws -> T) async throws -> T {
        let span = ServiceContext.current
        return try await database.write { db in
            try ServiceContext.$current.withValue(span) {
                try updates(db)
            }
        }
    }

}

// MARK: - Value Observation

extension CacheService {

    /// Returns an AsyncSequence of observed values for the specified key and query
    func observing<Output>(
        scheduling scheduler: some ValueObservationScheduler = .async(onQueue: .main),
        bufferingPolicy: AsyncValueObservation<Output>.BufferingPolicy = .unbounded,
        query: @escaping (Database) throws -> Output
    ) throws -> AsyncValueSequence<Output> {
        let span = ServiceContext.current
        let observation = ValueObservation
            .tracking { db in
                try ServiceContext.$current.withValue(span) {
                    try query(db)
                }
            }
            .values(
                in: database,
                scheduling: scheduler,
                bufferingPolicy: bufferingPolicy
            )
        return AsyncValueSequence(base: observation)
    }

    /// Returns an AsyncSequence of observed values for the specified key and query
    func observing<Output>(
        region: any DatabaseRegionConvertible,
        scheduling scheduler: some ValueObservationScheduler = .async(onQueue: .main),
        bufferingPolicy: AsyncValueObservation<Output>.BufferingPolicy = .unbounded,
        query: @escaping (Database) throws -> Output
    ) throws -> AsyncValueSequence<Output> {
        let span = ServiceContext.current
        let observation = ValueObservation
            .tracking(region: region) { db in
                try ServiceContext.$current.withValue(span) {
                    try query(db)
                }
            }
            .values(
                in: database,
                scheduling: scheduler,
                bufferingPolicy: bufferingPolicy
            )
        return AsyncValueSequence(base: observation)
    }

    /// Returns an AsyncSequence of observed values for the specified key and query
    func observing<Output>(
        regions: (any DatabaseRegionConvertible)...,
        scheduling scheduler: some ValueObservationScheduler = .async(onQueue: .main),
        bufferingPolicy: AsyncValueObservation<Output>.BufferingPolicy = .unbounded,
        query: @escaping (Database) throws -> Output
    ) throws -> AsyncValueSequence<Output> {
        let span = ServiceContext.current
        let observation = ValueObservation
            .tracking(regions: regions) { db in
                try ServiceContext.$current.withValue(span) {
                    try query(db)
                }
            }
            .values(
                in: database,
                scheduling: scheduler,
                bufferingPolicy: bufferingPolicy
            )
        return AsyncValueSequence(base: observation)
    }

}
