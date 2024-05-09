
import ArgumentParser

@main
struct MainCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "The main highly distributed and highly available (and highly secure) BokBank backend",
        subcommands: [
            ServeCommand.self,
        ],
        defaultSubcommand: ServeCommand.self
    )

}
