import XCTest
import UndercutF1Host
import UndercutF1Web

final class WebServiceConfigurationTests: XCTestCase {
    func testDisabledConfigurationDoesNotStartService() async throws {
        let services = ApplicationServices()
        let webService = WebService(environment: .testing)
        try await webService.start(configuration: .init(isEnabled: false), services: services)
        webService.shutdown()
    }
}
