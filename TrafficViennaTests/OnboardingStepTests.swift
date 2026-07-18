import XCTest
@testable import TrafficVienna

final class OnboardingStepTests: XCTestCase {
    func testStepsFollowTheCompleteOnboardingJourney() {
        var steps: [OnboardingStep] = []
        var step: OnboardingStep? = .departures

        while let current = step {
            steps.append(current)
            step = current.next
        }

        XCTAssertEqual(steps, [.departures, .disruptions, .personal, .account])
        XCTAssertEqual(steps, OnboardingStep.allCases)
    }

    func testOptionalAccountIsTheFinalStep() {
        XCTAssertNil(OnboardingStep.account.next)
    }
}
