@MainActor
protocol LiveActivityStarting {
    var isAvailable: Bool { get }

    func start(
        line: String,
        destination: String,
        stop: String,
        minutes: Int,
        isLive: Bool
    ) throws
}
