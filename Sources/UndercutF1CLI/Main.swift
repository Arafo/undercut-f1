import ArgumentParser

@main
struct UndercutF1CLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "undercutf1",
        abstract: "Swift CLI port of the Undercut F1 console",
        version: "0.1.0",
        subcommands: [
            RootCommand.self,
            ImportCommand.self,
            InfoCommand.self,
            ImageCommand.self,
            LoginCommand.self,
            LogoutCommand.self
        ],
        defaultSubcommand: RootCommand.self
    )

    func run() async throws {}
}
