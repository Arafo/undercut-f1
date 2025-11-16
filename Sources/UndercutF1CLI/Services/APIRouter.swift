import Foundation
import Logging
import NIOCore
import NIOHTTP1
import UndercutF1Data

struct APIResponse: Sendable {
    var status: HTTPResponseStatus
    var headers: HTTPHeaders
    var body: ByteBuffer?
}

enum ControlOperation: String, Codable, Sendable {
    case pauseClock = "PauseClock"
    case resumeClock = "ResumeClock"
    case toggleClock = "ToggleClock"
}

struct ControlRequest: Codable, Sendable {
    let operation: String
}

enum ControlErrorCode: String, Codable, Sendable {
    case noRunningSession = "NoRunningSession"
    case unknownOperation = "UnknownOperation"
}

struct ControlError: Codable, Sendable {
    let errorCode: ControlErrorCode
    let errorMessage: String

    init(errorCode: ControlErrorCode) {
        self.errorCode = errorCode
        switch errorCode {
        case .noRunningSession:
            self.errorMessage = "No session is currently running"
        case .unknownOperation:
            self.errorMessage = "Unknown operation requested"
        }
    }
}

struct ControlResponse: Codable, Sendable {
    let clockPaused: Bool
    let sessionRunning: Bool
    let sessionName: String?
}

struct QueueSnapshotItem: Codable, Sendable {
    let type: String
    let data: String?
    let timestamp: Date
}

struct LapHistoryResponse: Codable, Sendable {
    let lapNumber: Int
    let drivers: [String: TimingDataPoint.Driver]
}

struct APIMessageResponse: Codable, Sendable {
    let message: String
}

actor APIRouter {
    private let context: APIContext
    private let logger: Logger
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let allocator = ByteBufferAllocator()

    init(context: APIContext, logger: Logger) {
        self.context = context
        self.logger = logger

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func handle(head: HTTPRequestHead?, body: ByteBuffer?) async -> APIResponse {
        guard let head else {
            return jsonResponse(APIMessageResponse(message: "Invalid request"), status: .badRequest)
        }

        let pathOnly = head.uri.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? head.uri
        let components = pathOnly.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        let lowered = components.map { $0.lowercased() }

        switch (head.method, lowered) {
        case (.GET, ["control"]):
            return await controlStateResponse()
        case (.POST, ["control"]):
            return await handleControlPost(body: body)
        case (.GET, ["snapshots", "queue"]):
            return await queueSnapshotResponse()
        case (.GET, let comps) where comps.first == "laps" && comps.count == 2:
            let parameter = components[1]
            if parameter.lowercased() == "best" {
                return bestLapResponse()
            } else if let lapNumber = Int(parameter) {
                return lapHistoryResponse(lapNumber: lapNumber)
            }
            return jsonResponse(APIMessageResponse(message: "Lap parameter must be a number or 'best'."), status: .badRequest)
        default:
            return jsonResponse(APIMessageResponse(message: "Not Found"), status: .notFound)
        }
    }

    private func controlStateResponse() async -> APIResponse {
        let response = ControlResponse(
            clockPaused: await context.dateTimeProvider.isPaused(),
            sessionRunning: context.sessionInfoProcessor.latest.name != nil,
            sessionName: context.sessionInfoProcessor.latest.name
        )
        return jsonResponse(response)
    }

    private func handleControlPost(body: ByteBuffer?) async -> APIResponse {
        guard let data = bodyData(body), !data.isEmpty else {
            return jsonResponse(APIMessageResponse(message: "Request body is required."), status: .badRequest)
        }

        do {
            let request = try decoder.decode(ControlRequest.self, from: data)
            guard let operation = ControlOperation(rawValue: request.operation) else {
                return jsonResponse(ControlError(errorCode: .unknownOperation), status: .badRequest)
            }
            guard context.sessionInfoProcessor.latest.name != nil else {
                return jsonResponse(ControlError(errorCode: .noRunningSession), status: .badRequest)
            }

            switch operation {
            case .pauseClock:
                if !(await context.dateTimeProvider.isPaused()) {
                    await context.dateTimeProvider.togglePause()
                }
            case .resumeClock:
                if await context.dateTimeProvider.isPaused() {
                    await context.dateTimeProvider.togglePause()
                }
            case .toggleClock:
                await context.dateTimeProvider.togglePause()
            }

            return await controlStateResponse()
        } catch {
            logger.error("Failed to decode control request: \(error.localizedDescription)")
            return jsonResponse(APIMessageResponse(message: "Invalid control request payload."), status: .badRequest)
        }
    }

    private func queueSnapshotResponse() async -> APIResponse {
        let snapshot = await context.timingService.getQueueSnapshot()
        let items = snapshot.map { QueueSnapshotItem(type: $0.0, data: $0.1, timestamp: $0.2) }
        return jsonResponse(items)
    }

    private func lapHistoryResponse(lapNumber: Int) -> APIResponse {
        guard let data = context.timingDataProcessor.driversByLap[lapNumber], !data.isEmpty else {
            return jsonResponse(APIMessageResponse(message: "No data found for lap \(lapNumber)."), status: .notFound)
        }
        return jsonResponse(LapHistoryResponse(lapNumber: lapNumber, drivers: data))
    }

    private func bestLapResponse() -> APIResponse {
        let best = context.timingDataProcessor.bestLaps
        return jsonResponse(best)
    }

    private func bodyData(_ body: ByteBuffer?) -> Data? {
        guard var buffer = body else { return nil }
        return buffer.readData(length: buffer.readableBytes)
    }

    private func jsonResponse<T: Encodable>(_ payload: T, status: HTTPResponseStatus = .ok) -> APIResponse {
        do {
            let data = try encoder.encode(payload)
            var buffer = allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)
            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "application/json")
            return APIResponse(status: status, headers: headers, body: buffer)
        } catch {
            logger.error("Failed to encode response: \(error.localizedDescription)")
            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
            var buffer = allocator.buffer(capacity: 0)
            buffer.writeString("Internal Server Error")
            return APIResponse(status: .internalServerError, headers: headers, body: buffer)
        }
    }
}
