struct SystemLiveActivityStarter: LiveActivityStarting {
    nonisolated init() {}

    var isAvailable: Bool {
        LiveActivityController.isAvailable
    }

    func start(
        line: String,
        destination: String,
        stop: String,
        minutes: Int,
        isLive: Bool
    ) throws {
        try LiveActivityController.track(
            line: line,
            destination: destination,
            stop: stop,
            minutes: minutes,
            isLive: isLive
        )
    }

    func update(
        line: String,
        destination: String,
        stop: String,
        minutes: Int,
        isLive: Bool
    ) {
        LiveActivityController.update(
            line: line,
            destination: destination,
            stop: stop,
            minutes: minutes,
            isLive: isLive
        )
    }

    func activeDepartureID(for stop: String) -> StationDepartureID? {
        LiveActivityController.activeDepartureID(for: stop)
    }

    func stopAll() {
        LiveActivityController.stopAll()
    }
}
