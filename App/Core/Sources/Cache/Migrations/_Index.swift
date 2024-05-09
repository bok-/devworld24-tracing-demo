import GRDB

enum Migrations {

    typealias Migration = (String, (Database) throws -> Void)

    static var allMigrations: [Migration] = [
        creation,
    ]

}


// MARK: - Helpers

func makeMigration(id: String, migrator: @escaping (Database) throws -> Void) -> Migrations.Migration {
    (id, migrator)
}
