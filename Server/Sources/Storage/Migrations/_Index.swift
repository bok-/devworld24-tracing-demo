import GRDB
import Utilities

enum Migrations {

    typealias Migration = (String, (String, Database) throws -> Void)

    /// A list of all migrations that should be run on a database, in order.
    static var allMigrations: [Migration] = [
        creation,
        demo,
    ]

}


// MARK: - Helpers

func makeMigration(id: String, migrator: @escaping (String, Database) throws -> Void) -> Migrations.Migration {
    (id, migrator)
}
