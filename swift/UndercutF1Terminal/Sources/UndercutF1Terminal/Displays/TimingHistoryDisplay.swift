import Foundation

public protocol TimingHistoryDisplayDataSource {
    var totalLapCount: Int { get }
    var chartOrigin: CursorPosition { get }

    func makeTimingHistoryNode(forLap lap: Int) async throws -> RenderNode
    func chartControlSequences(forLap lap: Int) async -> [String]
}

public final class TimingHistoryDisplay: Display {
    public let screen: Screen = .timingHistory

    private let state: State
    private let dataSource: TimingHistoryDisplayDataSource
    private var previousSequences: [String] = []

    public init(state: State, dataSource: TimingHistoryDisplayDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    public func render() async throws -> RenderNode {
        let lap = selectedLap()
        return try await dataSource.makeTimingHistoryNode(forLap: lap)
    }

    public func postRender(force: Bool, terminal: TerminalProtocol) async throws {
        let lap = selectedLap()
        let sequences = await dataSource.chartControlSequences(forLap: lap)
        guard !sequences.isEmpty else {
            previousSequences = []
            return
        }

        if force || sequences != previousSequences {
            await terminal.saveCursorPosition()
            await terminal.moveCursor(to: dataSource.chartOrigin)
            for sequence in sequences {
                await terminal.write(sequence)
            }
            await terminal.restoreCursorPosition()
            previousSequences = sequences
        }
    }

    private func selectedLap() -> Int {
        guard dataSource.totalLapCount > 0 else { return 1 }
        let clamped = max(0, min(state.cursorOffset, dataSource.totalLapCount - 1))
        return clamped + 1
    }
}
