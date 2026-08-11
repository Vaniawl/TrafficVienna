import Foundation

enum AppLaunchContext {
    static let uiTestingArgument = "-ui-testing"

    static var usesInertUnitTestScene: Bool {
        let processInfo = ProcessInfo.processInfo
        return usesInertUnitTestScene(
            arguments: processInfo.arguments,
            environment: processInfo.environment
        )
    }

    static func usesInertUnitTestScene(
        arguments: [String],
        environment: [String: String]
    ) -> Bool {
#if DEBUG
        let isHostedByXCTest = environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
        return isHostedByXCTest && !arguments.contains(uiTestingArgument)
#else
        false
#endif
    }
}
