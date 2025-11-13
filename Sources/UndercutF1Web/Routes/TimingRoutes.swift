import Vapor
import UndercutF1Data
import UndercutF1Host

enum TimingRoutes {
    static func register(
        on app: Application,
        services: ApplicationServices,
        latestTypes: [LiveTimingDataType]
    ) {
        let registry = services.timingDataRegistry

        for type in latestTypes {
            app.get("data", type.rawValue, "latest") { _ async throws -> Response in
                guard let payload = await registry.latest(for: type) else {
                    throw Abort(.notFound)
                }
                return try Response.json(payload)
            }
        }

        app.get("data", LiveTimingDataType.timingData.rawValue, "laps", ":lapNumber") { request async throws -> Response in
            guard let lapNumber = request.parameters.get("lapNumber", as: Int.self) else {
                throw Abort(.badRequest)
            }
            guard let payload = await registry.lap(number: lapNumber) else {
                throw Abort(.notFound)
            }
            return try Response.json(payload)
        }

        app.get("data", LiveTimingDataType.timingData.rawValue, "laps", "best") { _ async throws -> Response in
            guard let payload = await registry.bestLaps() else {
                throw Abort(.notFound)
            }
            return try Response.json(payload)
        }
    }
}
