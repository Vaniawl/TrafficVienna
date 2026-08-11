import SwiftUI
import UIKit
import XCTest
@testable import TrafficVienna

final class DesignColorContrastTests: XCTestCase {
    private let minimumTextContrast = 4.5

    func testHeroGradientSupportsWhiteText() throws {
        let light = UITraitCollection(userInterfaceStyle: .light)

        try assertContrast(
            foreground: .white,
            background: DesignColor.heroStart,
            traits: light,
            atLeast: minimumTextContrast
        )
        try assertContrast(
            foreground: .white,
            background: DesignColor.heroEnd,
            traits: light,
            atLeast: minimumTextContrast
        )
    }

    func testSemanticTextColorsMeetContrastInLightAndDarkAppearances() throws {
        let roles = [
            DesignColor.accentText,
            DesignColor.success,
            DesignColor.warning,
            DesignColor.error,
            DesignColor.info,
        ]

        for traits in [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(userInterfaceStyle: .dark),
        ] {
            for role in roles {
                try assertContrast(
                    foreground: role,
                    background: DesignColor.background,
                    traits: traits,
                    atLeast: minimumTextContrast
                )
            }
        }
    }

    func testTextHierarchyMeetsContrastOnSupportedSurfaces() throws {
        for traits in [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(userInterfaceStyle: .dark),
        ] {
            for foreground in [
                DesignColor.primaryText,
                DesignColor.secondaryText,
                DesignColor.tertiaryText,
            ] {
                for background in [
                    DesignColor.background,
                    DesignColor.cardBackground,
                    DesignColor.elevatedBackground,
                ] {
                    try assertContrast(
                        foreground: foreground,
                        background: background,
                        traits: traits,
                        atLeast: minimumTextContrast
                    )
                }
            }
        }
    }

    func testLineBadgesChooseReadableForegroundColors() throws {
        let traits = UITraitCollection(userInterfaceStyle: .light)

        for line in ["U1", "U2", "U3", "U4", "U6", "U7", "S1", "D", "13A", "N25"] {
            try assertContrast(
                foreground: LineColors.foregroundColor(for: line),
                background: LineColors.color(for: line),
                traits: traits,
                atLeast: minimumTextContrast
            )
        }
    }

    private func assertContrast(
        foreground: Color,
        background: Color,
        traits: UITraitCollection,
        atLeast minimum: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let foregroundComponents = try XCTUnwrap(
            Components(color: UIColor(foreground).resolvedColor(with: traits)),
            file: file,
            line: line
        )
        let backgroundComponents = try XCTUnwrap(
            Components(color: UIColor(background).resolvedColor(with: traits)),
            file: file,
            line: line
        )
        let ratio = foregroundComponents.contrastRatio(with: backgroundComponents)

        XCTAssertGreaterThanOrEqual(ratio, minimum, file: file, line: line)
    }
}

private struct Components {
    let red: Double
    let green: Double
    let blue: Double

    init?(color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
    }

    func contrastRatio(with other: Components) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private var relativeLuminance: Double {
        0.2126 * red.linearized
            + 0.7152 * green.linearized
            + 0.0722 * blue.linearized
    }
}

private extension Double {
    var linearized: Double {
        self <= 0.04045
            ? self / 12.92
            : pow((self + 0.055) / 1.055, 2.4)
    }
}
