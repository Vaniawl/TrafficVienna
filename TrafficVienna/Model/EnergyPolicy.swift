import Combine
import Foundation
import SwiftUI

struct EnergyPolicy: Hashable {
    let isLowDataMode: Bool
    let isLowPowerMode: Bool
    let isThermallyConstrained: Bool

    var usesConstrainedPolling: Bool {
        isLowDataMode || isLowPowerMode || isThermallyConstrained
    }

    var allowsContinuousAnimation: Bool {
        !isLowPowerMode && !isThermallyConstrained
    }
}

@MainActor
final class EnergyMonitor: ObservableObject {
    @Published private(set) var isLowPowerModeEnabled: Bool
    @Published private(set) var isThermallyConstrained: Bool

    private let notificationCenter: NotificationCenter
    private let currentLowPowerValue: () -> Bool
    private let currentThermalValue: () -> Bool
    private var observers: [NSObjectProtocol] = []

    init(
        notificationCenter: NotificationCenter = .default,
        currentLowPowerValue: @escaping () -> Bool = { ProcessInfo.processInfo.isLowPowerModeEnabled },
        currentThermalValue: @escaping () -> Bool = {
            switch ProcessInfo.processInfo.thermalState {
            case .serious, .critical: true
            case .nominal, .fair: false
            @unknown default: true
            }
        }
    ) {
        self.notificationCenter = notificationCenter
        self.currentLowPowerValue = currentLowPowerValue
        self.currentThermalValue = currentThermalValue
        isLowPowerModeEnabled = currentLowPowerValue()
        isThermallyConstrained = currentThermalValue()
        observers.append(notificationCenter.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isLowPowerModeEnabled = self.currentLowPowerValue()
            }
        })
        observers.append(notificationCenter.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isThermallyConstrained = self.currentThermalValue()
            }
        })
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }
}

private struct ContinuousAnimationKey: EnvironmentKey {
    static let defaultValue = true
}

private struct LowPowerModeKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ThermallyConstrainedKey: EnvironmentKey {
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

    var isThermallyConstrained: Bool {
        get { self[ThermallyConstrainedKey.self] }
        set { self[ThermallyConstrainedKey.self] = newValue }
    }
}
