import Foundation

public protocol FooterRenderer {
    var footerHeight: Int { get }
    func renderFooter() -> RenderNode
}

public final class CommandFooterRenderer: FooterRenderer {
    private let inputHandlers: [InputHandler]
    private let state: State

    public let footerHeight = 1

    public init(inputHandlers: [InputHandler], state: State) {
        self.inputHandlers = inputHandlers
        self.state = state
    }

    public func renderFooter() -> RenderNode {
        let commands = inputHandlers
            .filter { handler in
                handler.isEnabled && handler.applicableScreens.contains(state.currentScreen)
            }
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { handler in
                "[\(handler.displayKeys.displayCharacters)] \(handler.description)"
            }
            .map(SimpleTextNode.init)

        return ColumnsNode(columns: commands)
    }
}
