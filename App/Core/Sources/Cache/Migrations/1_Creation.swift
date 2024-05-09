
import Foundation
import GRDB
import Models
import OTel

extension Migrations {

    /// Initial table creation
    static let creation = makeMigration(id: "creation") { db in

        // Accounts table
        try db.create(table: "account") { table in
            table.column("id", .text).notNull().primaryKey()
            table.column("bsb", .text).notNull()
            table.column("number", .text).notNull()
            table.column("name", .text).notNull()
            table.column("product", .text)
            table.column("balance", .jsonText).notNull()
            table.column("updatedBy", .text)
        }

        // Merchants Table
        try db.create(table: "merchant") { table in
            table.column("id", .text).notNull().primaryKey()
            table.column("name", .text).notNull()
            table.column("address", .text)
            table.column("location", .jsonText)
            table.column("logoURL", .text).notNull()
            table.column("updatedBy", .text)
        }

        // Transactions Table
        try db.create(table: "transaction") { table in
            table.column("id", .text).notNull().primaryKey()
            table.column("accountID", .text).notNull()
            table.column("instant", .datetime).notNull()
            table.column("amount", .jsonText).notNull()
            table.column("description", .text).notNull()
            table.column("category", .text).notNull()
            table.column("details", .jsonText).notNull()
            table.column("updatedBy", .text)
        }

    }

}
