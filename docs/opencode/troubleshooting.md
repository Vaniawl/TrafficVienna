# OpenCode Troubleshooting

## `xcodebuild: command not found`

TrafficVienna is an iOS app. Full build and test require macOS with Xcode. On Linux, run repository-only checks with:

```bash
TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1 bash scripts/ci.sh
```

GitHub Actions uses macOS and should run the real Xcode build and tests.

## `Unable to find a device matching ... iPhone 17`

`scripts/build.sh` uses a generic iOS Simulator destination by default. XCTest
uses `iPhone 17` unless `TRAFFICVIENNA_XCODE_DESTINATION` is set. If the macOS
runner has no concrete `iPhone 17` simulator, `scripts/test.sh` records an
explicit XCTest skip after repository and OpenCode validation pass.

## `There are no test bundles available to test`

The shared `TrafficVienna` scheme includes both `TrafficViennaTests` and `TrafficViennaUITests`. This message indicates a project/scheme wiring regression and `scripts/test.sh` treats it as a failure. Confirm both targets still appear in `xcodebuild -project TrafficVienna.xcodeproj -list` and both `TestableReference` entries remain in the shared scheme.

## `opencode: command not found`

Install the OpenCode CLI for local config validation:

```bash
npm install --global opencode-ai@1.17.20
```

Do not install Astro or unrelated global tools for this repository.

## Draft PR cannot be created

Verify GitHub CLI authentication for the personal account:

```bash
gh auth status
gh repo view Vaniawl/TrafficVienna
```

If `gh` is authenticated to another account, stop and ask the user before changing authentication.
