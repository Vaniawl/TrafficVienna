import XCTest
@testable import TrafficVienna

final class OnboardingStepTests: XCTestCase {
    func testStepsFollowTheCompleteOnboardingJourney() async {
        var steps: [OnboardingStep] = []
        var step: OnboardingStep? = .departures

        while let current = step {
            steps.append(current)
            step = current.next
        }

        XCTAssertEqual(steps, [.departures, .disruptions, .personal])
        XCTAssertEqual(steps, OnboardingStep.allCases)
    }

    func testPersonalisationIsTheFinalStep() async {
        XCTAssertNil(OnboardingStep.personal.next)
    }
}
