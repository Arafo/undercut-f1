import Foundation

public protocol DriverTrackerDisplayDataSource {
    var trackMapOrigin: CursorPosition { get }

    func driverTowerNode(cursorOffset: Int) async throws -> RenderNode
    func statusPanelNode() async -> RenderNode
    func trackMapMessageNode() async -> RenderNode
    func trackMapSequences() async -> [String]
}

public final class DriverTrackerDisplay: Display {
    public let screen: Screen = .driverTracker

    private let state: State
    private let dataSource: DriverTrackerDisplayDataSource
    private var previousSequences: [String] = []

    public init(state: State, dataSource: DriverTrackerDisplayDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        let driverTower = try await dataSource.driverTowerNode(cursorOffset: state.cursorOffset)
        let status = await dataSource.statusPanelNode()
        let trackMapMessage = await dataSource.trackMapMessageNode()

        let leftColumn = RowsNode(rows: [driverTower, status])
        return ColumnsNode(columns: [leftColumn, trackMapMessage])
    }

    public func postRender(force: Bool, terminal: TerminalProtocol) async throws {
        let sequences = await dataSource.trackMapSequences()
        guard !sequences.isEmpty else {
            previousSequences = []
            return
        }

        if force || sequences != previousSequences {
            await terminal.saveCursorPosition()
            await terminal.moveCursor(to: dataSource.trackMapOrigin)
            for sequence in sequences {
                await terminal.write(sequence)
            }
            await terminal.restoreCursorPosition()
            previousSequences = sequences
        }
    }
}
