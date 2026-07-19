import Combine
import Foundation
import SwiftUI

struct EnergyPolicy: Hashable {
    let isLowDataMode: Bool
    let isLowPowerMode: Bool

    var usesConstrainedPolling: Bool {
        isLowDataMode || isLowPowerMode
    }

    var allowsContinuousAnimation: Bool {
        !isLowPowerMode
    }
}

@MainActor
final class EnergyMonitor: ObservableObject {
    @Published private(set) var isLowPowerModeEnabled: Bool

    private let notificationCenter: NotificationCenter
    private let currentValue: () -> Bool
    private var observer: NSObjectProtocol?

    init(
        notificationCenter: NotificationCenter = .default,
        currentValue: @escaping () -> Bool = { ProcessInfo.processInfo.isLowPowerModeEnabled }
    ) {
        self.notificationCenter = notificationCenter
        self.currentValue = currentValue
        isLowPowerModeEnabled = currentValue()
        observer = notificationCenter.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isLowPowerModeEnabled = self.currentValue()
            }
        }
    }

    deinit {
        if let observer {
            notificationCenter.removeObserver(observer)
        }
    }
}

private struct ContinuousAnimationKey: EnvironmentKey {
    static let defaultValue = true
}

private struct LowPowerModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var allowsContinuousAnimation: Bool {
        get { self[ContinuousAnimationKey.self] }
        set { self[ContinuousAnimationKey.self] = newValue }
    }

    var isLowPowerMode: Bool {
        get { self[LowPowerModeKey.self] }
        set { self[LowPowerModeKey.self] = newValue }
    }
}
