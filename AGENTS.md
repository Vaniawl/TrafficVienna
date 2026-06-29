# TrafficVienna — Agent rules

- Build: `xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Run tests: `xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test`
- Memory: on start read `memory/JOURNAL.md` and `memory/DECISIONS.md` for context. After each task, append a short summary to `memory/JOURNAL.md` (newest first). Record architectural decisions in `memory/DECISIONS.md`.
