import Foundation

public struct TimingTowerRow {
    public let positionLabel: String
    public let leaderGap: String
    public let interval: String
    public let bestLap: String
    public let lastLap: String
    public let sector1: String
    public let sector2: String
    public let sector3: String
    public let pit: String
    public let tyre: String
    public let comparison: String
    public let driverTag: String

    public init(
        positionLabel: String,
        leaderGap: String,
        interval: String,
        bestLap: String,
        lastLap: String,
        sector1: String,
        sector2: String,
        sector3: String,
        pit: String,
        tyre: String,
        comparison: String,
        driverTag: String
    ) {
        self.positionLabel = positionLabel
        self.leaderGap = leaderGap
        self.interval = interval
        self.bestLap = bestLap
        self.lastLap = lastLap
        self.sector1 = sector1
        self.sector2 = sector2
        self.sector3 = sector3
        self.pit = pit
        self.tyre = tyre
        self.comparison = comparison
        self.driverTag = driverTag
    }
}

public protocol TimingTowerDataProvider {
    var lapHeadline: String { get }
    var isRace: Bool { get }
    var raceRows: [TimingTowerRow] { get }
    var nonRaceHeader: [String] { get }
    var nonRaceRows: [[String]] { get }
    var statusPanel: RenderNode { get }
    var raceControlPanel: RenderNode { get }
    var comparisonIndex: Int? { get }
}

public final class TimingTowerDisplay: Display {
    public let screen: Screen = .timingTower

    private let provider: TimingTowerDataProvider

    public init(provider: TimingTowerDataProvider) {
        self.provider = provider
    }

    public func render() async throws -> RenderNode {
        let timingNode: RenderNode
        if provider.isRace {
            var table = TableNode(
                columns: [
                    .init(title: provider.lapHeadline, width: 9, alignment: .left),
                    .init(title: "Leader", width: 8, alignment: .right),
                    .init(title: "Gap", width: 8, alignment: .right),
                    .init(title: "Best", width: 9, alignment: .right),
                    .init(title: "Last", width: 9, alignment: .right),
                    .init(title: "S1", width: 7, alignment: .right),
                    .init(title: "S2", width: 7, alignment: .right),
                    .init(title: "S3", width: 7, alignment: .right),
                    .init(title: "Pit", width: 4, alignment: .right),
                    .init(title: "Tyre", width: 5, alignment: .right),
                    .init(title: "Compare", width: 9, alignment: .right),
                    .init(title: "Driver", width: 9, alignment: .left)
                ]
            )

            for row in provider.raceRows {
                table.addRow([
                    row.positionLabel,
                    row.leaderGap,
                    row.interval,
                    row.bestLap,
                    row.lastLap,
                    row.sector1,
                    row.sector2,
                    row.sector3,
                    row.pit,
                    row.tyre,
                    row.comparison,
                    row.driverTag
                ])
            }
            timingNode = table
        } else {
            var table = TableNode(
                columns: provider.nonRaceHeader.enumerated().map { index, title in
                    TableNode.Column(title: title, alignment: index == 0 ? .left : .right)
                }
            )
            for row in provider.nonRaceRows {
                table.addRow(row)
            }
            timingNode = table
        }

        let content = RowsNode(
            rows: [
                timingNode,
                ColumnsNode(columns: [provider.statusPanel, provider.raceControlPanel])
            ]
        )
        return content
    }
}
