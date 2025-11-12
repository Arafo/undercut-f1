import ArgumentParser

@main
struct UndercutF1CLI: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "undercutf1",
        abstract: "A Swift port of the undercutf1 command line interface.",
        subcommands: [
            ImportCommand.self,
            InfoCommand.self,
            ImageCommand.self,
            LoginCommand.self,
            LogoutCommand.self
        ]
    )

    @OptionGroup()
    var options: RootOptions

    func run() throws {
        CommandHandler.root(options: options)
    }
}
