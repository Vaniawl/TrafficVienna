# Status

- Status: CONTINUE
- Workspace: `/Users/ivandovhosheia/Swift/TrafficVienna`
- Branch: `codex/system-surfaces-readiness`
- Stack: native SwiftUI iOS application, widget extension, XCTest, and XCUITest.
- Current phase: continued reliability improvements on the existing draft PR.
- Product shell: Home, Discover, Alerts, and Saved; accounts are out of scope.
- Verified tests: 167/167 pass on iPhone 17 Simulator (163 model/service tests
  and 4 UI tests), with zero failures or skips. App and widget build successfully.
- Verified visual coverage: four journeys and key secondary surfaces were
  exercised on iPhone 17; Home, Station Detail, and reminder management were
  inspected in light mode, dark mode, and accessibility Dynamic Type. A 13-inch
  iPad Simulator provides supplementary adaptive-layout evidence.
- Verified architecture/security review: no Blocking finding. Important findings
  were addressed by restoring ActivityKit ownership, blocking new system
  countdowns from stale data, revalidating reminder timing after permission,
  removing body-time formatter allocation, improving reminder row reflow, and
  making repeated reminders for one route idempotent. Location authorization is
  now authoritative over cached coordinates and Map projection. Widget samples
  are confined to Gallery previews and cannot appear in an empty runtime snapshot.
  Saved-route reloads coalesce without losing repository changes or a queued
  forced refresh, and obsolete results cannot overwrite UI/widget state. Station
  Detail and Alerts likewise preserve a manual forced refresh behind active
  polling, suppress the obsolete pass, and discard queued work on cancellation.
  Nearby now serializes refresh ownership, carries the strongest force intent to
  the latest captured location, and lets a surviving caller take ownership when
  SwiftUI cancels the former location task. Root navigation now owns one path per
  tab: external destinations reset only their target path, while a notification
  replaces Discover with exactly the requested station and ordinary tab changes
  preserve the user's current stacks. Widget countdown projection now keeps a
  separate per-route source timestamp, so cached Saved departures cannot be
  presented as newly refreshed; mixed rows display the oldest visible source.
- Verified quality: Xcode static analysis passes; app extraction reports 267
  keys with 0 missing catalogue/German values and widget extraction reports 31
  with 0 missing catalogue/German values. Both repository structural validators,
  `git diff --check`, and the scoped secret/new-endpoint scan pass.
- Infrastructure limitation: `bash scripts/ci.sh` reaches the permission matcher
  and exits 127 because the required global `opencode` CLI is not installed.
  The reliability script's Python and timeout fixtures pass before the same
  missing-tool boundary. Hosted Quality run `30764256748` supplied the pinned
  CLI and passed the previously published complete wrapper.
- Handoff: draft PR #15 tracks `codex/system-surfaces-readiness` against protected
  `main`; each published update must pass its protected validation.
- The current slice passes its local gates; protected CI remains the publication
  authority. Broader product improvement remains active; do not merge or release
  without explicit approval.
- Warm-link Simulator acceptance reproduced the stale Stephansplatz detail and
  verified that `trafficvienna://search` now returns to the Discover root; paired
  before/after screenshots were inspected at 368×800.
- Home Screen widget acceptance reproduced a legacy stale payload reporting only
  about two minutes since its projection anchor, then verified the corrected
  medium widget reporting the roughly 23-minute source age while its departure
  countdown continued updating.
- External release gates: distribution signing, App Store Connect processed build,
  and signed physical-device TestFlight acceptance are not provided by Simulator
  evidence.
