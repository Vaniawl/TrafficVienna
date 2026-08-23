# Theme and design tokens

## Compact token summary

### Platform and typography

- Platform: native SwiftUI, iPhone-first, iOS system navigation and controls.
- Font family: SF Pro via SwiftUI semantic text styles. SF Pro Rounded is not used.
- Type ramp: `largeTitle`, `title2`, `title3`, `headline`, `body`, `subheadline`, `footnote`, `caption`.
- Numeric departure times use monospaced digits.
- Dynamic Type is first-class; accessibility sizes swap compact rows for stacked layouts.

### Current color layer

- `brand`: `#E20917` Vienna red.
- `brandDeep`: `#A90712`.
- `brandGradient`: top-leading brand → bottom-trailing brandDeep.
- Background: `systemGroupedBackground`.
- Card: `secondarySystemGroupedBackground`.
- Primary/secondary/tertiary text: semantic iOS label colors.
- Border: `systemGray4`; separator: `systemGray3`.
- Success, warning, error, info: semantic system green/orange/red/blue.
- Light and dark appearance come from semantic iOS colors, not separate hardcoded palettes.

### Spacing

- none `0`
- xxs `4`
- xs `8`
- sm `12`
- md `16`
- lg `20`
- xl `24`
- xxl `32`
- xxxl `48`

### Corner radius

- none `0`
- xs `4`
- sm `8`
- md `12`
- lg `16`
- xl `24`
- full capsule `9999`

### Shadows

- sm: black 4%, radius 4, y 2.
- md: black 6%, radius 12, y 5.
- lg: black 8%, radius 20, y 10.
- Surfaces generally use either one hairline border or one restrained shadow, never both heavily.

### Motion

- quick: snappy, 280 ms, no extra bounce.
- standard: smooth, 380 ms, no extra bounce.
- live pulse: ease-in-out, 900 ms.
- shimmer: linear, 1250 ms.
- State replacement: opacity + scale 0.985.
- Edge presentation: move from the relevant edge + opacity.
- Reduce Motion removes translation, scale, pulse, shimmer, and rolling numbers.

### Layout and accessibility

- iPhone compact width is the primary breakpoint; horizontal padding 16.
- Regular width increases main content horizontal padding to 48.
- Minimum interactive target is 44×44 points.
- Use native safe areas and system tab/navigation bars.

## Raw source dumps

### `TrafficVienna/Model/DesignColor.swift`

```swift
import SwiftUI

enum DesignColor {
    static let brand = Color(hex: 0xE20917)
    static let brandDeep = Color(hex: 0xA90712)
    static let brandGradient = LinearGradient(
        colors: [brand, brandDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = Color(.systemGroupedBackground)
    static let secondaryBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)

    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    static let inverseText = Color.white

    static let border = Color(.systemGray4)
    static let separator = Color(.systemGray3)

    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)
    static let info = Color(.systemBlue)
}
```

### `TrafficVienna/Model/AppColors.swift`

```swift
import SwiftUI

extension ShapeStyle where Self == Color {
    static var appAccent: Color { DesignColor.brand }
    static var appFaint: Color { Color(.tertiaryLabel) }
    static var appOfflineBg: Color { Color.red.opacity(0.12) }
    static var appErrorBg: Color { Color.yellow.opacity(0.12) }
    static var appChipBg: Color { Color(.quaternarySystemFill) }
}
```

### `TrafficVienna/Model/Spacing.swift`

```swift
import CoreGraphics

enum Spacing {
    static let none: CGFloat = 0
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}
```

### `TrafficVienna/Model/CornerRadius.swift`

```swift
import CoreGraphics

enum CornerRadius {
    static let none: CGFloat = 0
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9_999
}
```

### `TrafficVienna/Model/Shadow.swift`

```swift
import SwiftUI

enum Shadow {
    static let none = (color: Color.clear, radius: 0.0, x: 0.0, y: 0.0)
    static let sm = (color: Color.black.opacity(0.04), radius: 4.0, x: 0.0, y: 2.0)
    static let md = (color: Color.black.opacity(0.06), radius: 12.0, x: 0.0, y: 5.0)
    static let lg = (color: Color.black.opacity(0.08), radius: 20.0, x: 0.0, y: 10.0)
}
```

### `TrafficVienna/Model/Motion.swift`

```swift
import SwiftUI

enum Motion {
    static let quick = Animation.snappy(duration: 0.28, extraBounce: 0)
    static let standard = Animation.smooth(duration: 0.38, extraBounce: 0)
    static let livePulse = Animation.easeInOut(duration: 0.9)
    static let shimmer = Animation.linear(duration: 1.25)

    static func quick(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : quick
    }

    static func standard(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : standard
    }

    static func stateTransition(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .opacity.combined(with: .scale(scale: 0.985))
        }
    }

    static func edgeTransition(_ edge: Edge, reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .move(edge: edge).combined(with: .opacity)
        }
    }
}
```
