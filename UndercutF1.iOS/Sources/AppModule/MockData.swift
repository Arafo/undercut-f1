import Foundation
import SwiftUI

enum MockData {
    static let drivers: [Driver] = [
        Driver(
            position: 1,
            code: "VER",
            name: "Max Verstappen",
            teamColor: Color(hex: 0x1E5BC6),
            tyre: .medium,
            tyreAge: 12,
            interval: "LEADER",
            gapToLeader: "0.0",
            relativeGap: "+0.0",
            lastLap: LapTiming(time: "1:17.245", isPersonalBest: false, isOverallBest: true),
            bestLap: LapTiming(time: "1:16.912", isPersonalBest: true, isOverallBest: true),
            sectorTimes: [
                SectorTiming(id: .one, time: "26.182", isPersonalBest: false, isOverallBest: true),
                SectorTiming(id: .two, time: "30.045", isPersonalBest: true, isOverallBest: true),
                SectorTiming(id: .three, time: "21.018", isPersonalBest: true, isOverallBest: false)
            ],
            positionChange: 0
        ),
        Driver(
            position: 2,
            code: "NOR",
            name: "Lando Norris",
            teamColor: Color(hex: 0xFF8000),
            tyre: .hard,
            tyreAge: 8,
            interval: "+1.7",
            gapToLeader: "+1.7",
            relativeGap: "+0.4",
            lastLap: LapTiming(time: "1:17.698", isPersonalBest: true, isOverallBest: false),
            bestLap: LapTiming(time: "1:17.698", isPersonalBest: true, isOverallBest: false),
            sectorTimes: [
                SectorTiming(id: .one, time: "26.492", isPersonalBest: true, isOverallBest: false),
                SectorTiming(id: .two, time: "30.311", isPersonalBest: false, isOverallBest: false),
                SectorTiming(id: .three, time: "20.895", isPersonalBest: true, isOverallBest: true)
            ],
            positionChange: +1
        ),
        Driver(
            position: 3,
            code: "HAM",
            name: "Lewis Hamilton",
            teamColor: Color(hex: 0x00A19C),
            tyre: .medium,
            tyreAge: 15,
            interval: "+2.9",
            gapToLeader: "+2.9",
            relativeGap: "+1.2",
            lastLap: LapTiming(time: "1:18.010", isPersonalBest: false, isOverallBest: false),
            bestLap: LapTiming(time: "1:17.835", isPersonalBest: true, isOverallBest: false),
            sectorTimes: [
                SectorTiming(id: .one, time: "26.701", isPersonalBest: false, isOverallBest: false),
                SectorTiming(id: .two, time: "30.449", isPersonalBest: false, isOverallBest: false),
                SectorTiming(id: .three, time: "20.860", isPersonalBest: true, isOverallBest: false)
            ],
            positionChange: -1
        ),
        Driver(
            position: 4,
            code: "LEC",
            name: "Charles Leclerc",
            teamColor: Color(hex: 0xED1C24),
            tyre: .soft,
            tyreAge: 5,
            interval: "+3.8",
            gapToLeader: "+3.8",
            relativeGap: "+2.1",
            lastLap: LapTiming(time: "1:18.221", isPersonalBest: true, isOverallBest: false),
            bestLap: LapTiming(time: "1:18.221", isPersonalBest: true, isOverallBest: false),
            sectorTimes: [
                SectorTiming(id: .one, time: "26.438", isPersonalBest: true, isOverallBest: false),
                SectorTiming(id: .two, time: "30.998", isPersonalBest: false, isOverallBest: false),
                SectorTiming(id: .three, time: "20.785", isPersonalBest: true, isOverallBest: false)
            ],
            positionChange: 0
        ),
        Driver(
            position: 5,
            code: "PIA",
            name: "Oscar Piastri",
            teamColor: Color(hex: 0xFF8000),
            tyre: .hard,
            tyreAge: 20,
            interval: "+6.6",
            gapToLeader: "+6.6",
            relativeGap: "+4.9",
            lastLap: LapTiming(time: "1:18.892", isPersonalBest: false, isOverallBest: false),
            bestLap: LapTiming(time: "1:18.405", isPersonalBest: true, isOverallBest: false),
            sectorTimes: [
                SectorTiming(id: .one, time: "26.910", isPersonalBest: false, isOverallBest: false),
                SectorTiming(id: .two, time: "31.205", isPersonalBest: false, isOverallBest: false),
                SectorTiming(id: .three, time: "20.777", isPersonalBest: false, isOverallBest: false)
            ],
            positionChange: 0
        )
    ]

    static let controlMessages: [RaceControlMessage] = [
        RaceControlMessage(timestamp: "Lap 18", message: "CAR 44 UNDER INVESTIGATION FOR PIT LANE INCIDENT", category: .investigation),
        RaceControlMessage(timestamp: "Lap 17", message: "DRIZZLE REPORTED IN TURNS 3 AND 4", category: .weather),
        RaceControlMessage(timestamp: "Lap 16", message: "CAR 81 FIVE SECOND TIME PENALTY FOR SPEEDING", category: .penalty),
        RaceControlMessage(timestamp: "Lap 15", message: "YELLOW FLAG SECTOR 2", category: .information)
    ]

    static let strategies: [DriverStrategy] = drivers.map { driver in
        DriverStrategy(
            driver: driver,
            stints: [
                Stint(tyre: driver.tyre, laps: max(4, driver.tyreAge - 4), pitStopTime: "2.4"),
                Stint(tyre: driver.tyre == .hard ? .medium : .hard, laps: driver.tyreAge + 6, pitStopTime: "2.6")
            ]
        )
    }

    static let trackerSnapshot = TrackerSnapshot(
        layoutName: "Monza",
        drivers: drivers.enumerated().map { index, driver in
            TrackerSnapshot.DriverPosition(
                driver: driver,
                progress: CGFloat(index) / CGFloat(max(1, drivers.count - 1)),
                highlighted: index == 0
            )
        }
    )

    static let sessionSummary = SessionSummary(
        name: "2025 Italian Grand Prix",
        circuit: "Monza",
        sessionType: "Race",
        lap: 18,
        totalLaps: 53,
        weather: "Light drizzle",
        trackStatus: "Yellow in Sector 2",
        controlMessages: controlMessages,
        driverStrategies: strategies,
        trackerSnapshot: trackerSnapshot
    )
}
