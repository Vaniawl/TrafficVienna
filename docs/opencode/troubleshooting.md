# OpenCode Troubleshooting

## `xcodebuild: command not found`

TrafficVienna is an iOS app. Full build and test require macOS with Xcode. On Linux, run repository-only checks with:

```bash
TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1 bash scripts/ci.sh
```

GitHub Actions uses macOS and should run the real Xcode build and tests.

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
