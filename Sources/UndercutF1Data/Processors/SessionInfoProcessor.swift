import Foundation

public protocol SessionInfoLogging: Sendable {
    func logInfo(_ message: String)
    func logDebug(_ message: String)
    func logError(_ message: String, error: Error)
}

public struct ConsoleSessionLogger: SessionInfoLogging {
    public init() {}
    public func logInfo(_ message: String) { print("[SessionInfo] INFO: \(message)") }
    public func logDebug(_ message: String) { print("[SessionInfo] DEBUG: \(message)") }
    public func logError(_ message: String, error: Error) { print("[SessionInfo] ERROR: \(message) -> \(error)") }
}

public final class SessionInfoProcessor: ProcessorBase<SessionInfoDataPoint> {
    private let httpClientFactory: HTTPClientFactory
    private let logger: SessionInfoLogging
    private var loadCircuitTask: Task<Void, Never>?

    public init(httpClientFactory: HTTPClientFactory, logger: SessionInfoLogging = ConsoleSessionLogger()) {
        self.httpClientFactory = httpClientFactory
        self.logger = logger
        super.init()
    }

    public override func didMerge(update: SessionInfoDataPoint, timestamp: Date) async {
        guard latest.circuitPoints.isEmpty,
              let circuitKey = latest.meeting?.circuit?.key,
              loadCircuitTask == nil else { return }

        let eventDate = latest.startDate
        loadCircuitTask = Task { [weak self] in
            await self?.loadCircuitPoints(circuitKey: circuitKey, eventDate: eventDate)
        }
    }

    private func loadCircuitPoints(circuitKey: Int, eventDate: Date?) async {
        logger.logInfo("Loading circuit data for key \(circuitKey)")
        let year = Calendar.current.component(.year, from: eventDate ?? Date())
        let path = "/api/v1/circuits/\(circuitKey)/\(year)"
        do {
            let (data, _) = try await httpClientFactory.data(for: path, client: .proxy)
            let response = try JSONDecoder().decode(CircuitInfoResponse.self, from: data)
            logger.logDebug("Received circuit info for key \(circuitKey)")
            mutateLatest { latest in
                latest.circuitPoints = Array(zip(response.x, response.y)).map { SessionInfoDataPoint.CircuitPoint(x: $0.0, y: $0.1) }
                latest.circuitCorners = response.corners.map { corner in
                    SessionInfoDataPoint.CircuitCorner(number: corner.number, x: corner.trackPosition.x, y: corner.trackPosition.y)
                }
                latest.circuitRotation = response.rotation
            }
        } catch {
            logger.logError("Failed to load circuit data for key \(circuitKey)", error: error)
        }
        loadCircuitTask = nil
    }
}

private struct CircuitInfoResponse: Decodable {
    let x: [Int]
    let y: [Int]
    let corners: [TrackCornerResponse]
    let rotation: Int

    struct TrackCornerResponse: Decodable {
        let number: Int
        let trackPosition: TrackPositionResponse
    }

    struct TrackPositionResponse: Decodable {
        let x: Float
        let y: Float
    }

    enum CodingKeys: String, CodingKey {
        case x = "X"
        case y = "Y"
        case corners = "Corners"
        case rotation = "Rotation"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let xValues = try container.decode([Double].self, forKey: .x)
        let yValues = try container.decode([Double].self, forKey: .y)
        x = xValues.map { Int($0.rounded()) }
        y = yValues.map { Int($0.rounded()) }
        corners = try container.decode([TrackCornerResponse].self, forKey: .corners)
        rotation = try container.decode(Int.self, forKey: .rotation)
    }
}
