import XCTest
@testable import TrafficVienna

final class AppLaunchContextTests: XCTestCase {
    func testSharedUnitTestSchemeUsesInertHostScene() async {
        XCTAssertTrue(AppLaunchContext.usesInertUnitTestScene)
    }

    func testUIAcceptanceArgumentKeepsTheRealAppScene() async {
        XCTAssertFalse(
            AppLaunchContext.usesInertUnitTestScene(
                arguments: [AppLaunchContext.uiTestingArgument],
                environment: ["XCTestConfigurationFilePath": "/tmp/tests.xctestconfiguration"]
            )
        )
    }

    func testNormalLaunchKeepsTheRealAppScene() async {
        XCTAssertFalse(
            AppLaunchContext.usesInertUnitTestScene(
                arguments: [],
                environment: [:]
            )
        )
    }
}
