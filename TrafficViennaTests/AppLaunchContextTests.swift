import XCTest
@testable import TrafficVienna

final class AppLaunchContextTests: XCTestCase {
    func testSharedUnitTestSchemeUsesInertHostScene() {
        XCTAssertTrue(AppLaunchContext.usesInertUnitTestScene)
    }

    func testUIAcceptanceArgumentKeepsTheRealAppScene() {
        XCTAssertFalse(
            AppLaunchContext.usesInertUnitTestScene(
                arguments: [AppLaunchContext.uiTestingArgument],
                environment: ["XCTestConfigurationFilePath": "/tmp/tests.xctestconfiguration"]
            )
        )
    }

    func testNormalLaunchKeepsTheRealAppScene() {
        XCTAssertFalse(
            AppLaunchContext.usesInertUnitTestScene(
                arguments: [],
                environment: [:]
            )
        )
    }
}
