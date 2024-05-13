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
import GRDB
import Tracing

/// Creates a GRDB TraceFunction that can be passed to `Database.trace(options:_:)`.
///
/// This function creates Tracing spans for each database operation based on the SQLite profiling info.
///
func makeGRDBTraceFunction() -> (Database.TraceEvent) -> Void {
    { event in
        // Unless it includes timing we can't create a span
        guard
            case let .profile(statement, duration) = event,
            let operationName = statement.sql.sqlOperation
        else {
            return
        }

        // We don't log top level events, they will be picked up our StorageService.read/write methods.
        guard ServiceContext.current != nil else {
            return
        }

        // The statement has just finished executing, so go back and calculate the start
        let end = DefaultTracerClock().now
        let start = DefaultTracerClock.Instant(nanosecondsSinceEpoch: end.nanosecondsSinceEpoch - UInt64(duration * Double(NSEC_PER_SEC)))

        let span = startSpan("\(operationName) db", at: start, ofKind: .client)
        span.updateAttributes { attributes in
            attributes.db.system = "sqlite"
            attributes.db.name = "cache"
            attributes.db.statement = statement.sql
        }
        span.end(at: end)
    }
}


// MARK: - Operation Detection

private extension String {

    // The OpenTelemetry specification cautions against attempting to parse the SQL statement to find
    // additional detail like the operation or table name, but we can (mostly) trivially get the operation
    // and it improves the usability of the resultant telemetry significantly. We won't try and get
    // the table name though, that would be very error-prone. There is probably something we could do here
    // with DatabaseRegionObserving but that can be a stretch goal.
    var sqlOperation: String? {
        let statement = uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // A rough attempt to represent the SQL language operations as supported by SQLite:
        // https://www.sqlite.org/lang.html
        //
        // We loop through this array looking for the first operation that begins with the key.
        // Because this is a loop we can support precedence and fallbacks.

        let operations: [String: String?] = [

            // These messages are dropped from telemetry
            "PRAGMA": nil,
            "--": nil,                  // SQL comments

            // Schema manipulation
            "ALTER TABLE": "ALTER TABLE",

            "CREATE UNIQUE INDEX": "CREATE INDEX",
            "CREATE INDEX": "CREATE INDEX",
            "DROP INDEX": "DROP INDEX",
            "REINDEX": "REINDEX",

            "CREATE TEMP TABLE": "CREATE TABLE",
            "CREATE TEMPORARY TABLE": "CREATE TABLE",
            "CREATE TABLE": "CREATE TABLE",
            "CREATE VIRTUAL TABLE": "CREATE VIRTUAL TABLE",
            "DROP TABLE": "DROP TABLE",

            "CREATE TEMP TRIGGER": "CREATE TRIGGER",
            "CREATE TEMPORARY TRIGGER": "CREATE TRIGGER",
            "CREATE TRIGGER": "CREATE TRIGGER",
            "DROP TRIGGER": "DROP TRIGGER",

            "CREATE TEMP VIEW": "CREATE VIEW",
            "CREATE TEMPORARY VIEW": "CREATE VIEW",
            "CREATE VIEW": "CREATE VIEW",
            "DROP VIEW": "DROP VIEW",

            // Data manipulation
            "DELETE": "DELETE",
            "INSERT": "INSERT",
            "REPLACE": "INSERT OR REPLACE",
            "SELECT": "SELECT",
            "UPDATE": "UPDATE",

            // Optimisation / clean up
            "ANALYZE": "ANALYZE",
            "EXPLAIN": "EXPLAIN",
            "VACUUM": "VACUUM",

            // Secondary Databases
            "ATTACH": "ATTACH DATABASE",
            "DETACH": "DETACH DATABASE",

            // Transactions
            "BEGIN": "BEGIN TRANSACTION",
            "COMMIT": "COMMIT TRANSACTION",
            "END": "END TRANSACTION",
            "ROLLBACK": "ROLLBACK TRANSACTION",

            // Savepoints
            "SAVEPOINT": "SAVEPOINT",
            "RELEASE": "RELEASE SAVEPOINT",

        ]

        for (prefix, operation) in operations where statement.hasPrefix(prefix) {
            return operation
        }

        return "UNKNOWN"
    }

}
