
import Dispatch
import Foundation
import GRDB
import Models
import os.lock
import Tracing
import TracingOpenTelemetrySemanticConventions
import Utilities

/// Main class for database access.
///
/// Databases are partitioned by User ID — each user gets their own database instance.
///
public final class StorageService: Sendable {

    public typealias PartitionKey = User.ID


    // MARK: - Database Partitions

    private let partitions = OSAllocatedUnfairLock(initialState: [PartitionKey: DatabasePool]())


    // MARK: - Initialisation and Creation

    public init() {
        // Intentionally left blank
    }

    /// Creates a database pool for the specified PartitionKey (User.ID)
    private static func makeDatabasePool(for key: PartitionKey) throws -> DatabasePool {
        try withSpan("Open Database") { span in
            span.updateAttributes { attributes in
                attributes.db.system = "sqlite"
                attributes.db.name = "db"
            }

            let pool = try DatabasePool(
                path: "Databases/\(key).sqlite",
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
                migrator.registerMigration(migration.0) { db in
                    try migration.1(key, db)
                }
            }
            try migrator.migrate(pool)

            return pool
        }
    }


    // MARK: - Database Access

    /// Retrieves the database pool for the specified PartitionKey (User.ID)
    private func partition(for key: PartitionKey) throws -> DatabasePool {
        try partitions.withLock { partitions in
            if let pool = partitions[key] {
                return pool
            }
            let pool = try Self.makeDatabasePool(for: key)
            partitions[key] = pool
            return pool
        }
    }

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
    /// - parameter key: The partition to read from.
    /// - parameter value: A closure which accesses the database.
    /// - throws: The error thrown by `value`, or any ``DatabaseError`` that
    ///   would happen while establishing the database access.
    ///
    func read<T>(from key: PartitionKey, _ value: @Sendable @escaping (Database) throws  -> T) async throws -> T {
        let span = ServiceContext.current
        return try await partition(for: key).read { db in
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
    /// - parameter key: The partition to write to.
    /// - parameter updates: A closure which accesses the database.
    /// - throws: The error thrown by `updates`, or any ``DatabaseError`` that
    ///   would happen while establishing the database access or committing
    ///   the transaction.
    ///
    func write<T>(to key: PartitionKey, _ updates: @Sendable @escaping (Database) throws -> T) async throws -> T {
        let span = ServiceContext.current
        return try await partition(for: key).write { db in
            try ServiceContext.$current.withValue(span) {
                try updates(db)
            }
        }
    }

}

// MARK: - Value Observation

extension StorageService {

    /// Returns an AsyncSequence of observed values for the specified partition key and query
    func observing<Output>(
        partition key: PartitionKey,
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
                in: try partition(for: key),
                scheduling: scheduler,
                bufferingPolicy: bufferingPolicy
            )
        return AsyncValueSequence(base: observation)
    }

    /// Returns an AsyncSequence of observed values for the specified partition key and query
    func observing<Output>(
        partition key: PartitionKey,
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
                in: try partition(for: key),
                scheduling: scheduler,
                bufferingPolicy: bufferingPolicy
            )
        return AsyncValueSequence(base: observation)
    }

    /// Returns an AsyncSequence of observed values for the specified partition key and query
    func observing<Output>(
        partition key: PartitionKey,
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
                in: try partition(for: key),
                scheduling: scheduler,
                bufferingPolicy: bufferingPolicy
            )
        return AsyncValueSequence(base: observation)
    }

}
