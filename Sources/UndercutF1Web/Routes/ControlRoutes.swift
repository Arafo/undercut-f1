import Vapor
import UndercutF1Host

enum ControlRoutes {
    static func register(on app: Application, services: ApplicationServices) {
        app.get("control") { _ async throws -> ControlResponse in
            await response(from: services)
        }

        app.post("control") { request async throws -> ControlResponse in
            do {
                let payload = try request.content.decode(ControlRequest.self)
                let snapshot = await services.sessionCache.current()
                guard snapshot.isRunning else {
                    throw ControlError(.noRunningSession)
                }

                let isPaused = await services.dateTimeProvider.isPaused()
                switch payload.operation {
                case .pauseClock where !isPaused:
                    await services.dateTimeProvider.togglePause()
                case .resumeClock where isPaused:
                    await services.dateTimeProvider.togglePause()
                case .toggleClock:
                    await services.dateTimeProvider.togglePause()
                default:
                    break
                }

                return await response(from: services)
            } catch let error as ControlError {
                throw error
            } catch {
                throw ControlError(.unknownOperation)
            }
        }
    }

    private static func response(from services: ApplicationServices) async -> ControlResponse {
        async let paused = services.dateTimeProvider.isPaused()
        async let snapshot = services.sessionCache.current()
        let values = await (paused, snapshot)
        return ControlResponse(
            clockPaused: values.0,
            sessionRunning: values.1.isRunning,
            sessionName: values.1.name
        )
    }
}
