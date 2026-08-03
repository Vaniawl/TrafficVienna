# Status

- Status: CONTINUE
- Workspace: `/Users/ivandovhosheia/Swift/TrafficVienna`
- Branch: `codex/system-surfaces-readiness`
- Stack: native SwiftUI iOS application, widget extension, XCTest, and XCUITest.
- Current phase: continued reliability improvements on the existing draft PR.
- Product shell: Home, Discover, Alerts, and Saved; accounts are out of scope.
- Verified tests: 197/197 pass on iPhone 17 Simulator (192 model/service tests
  and 5 UI tests), with zero failures or skips. App and widget build successfully.
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
  Saved-route reloads and targeted row retries share one serialized owner: they
  coalesce without losing repository changes or force intent, obsolete results
  cannot overwrite UI/widget state, and cancellation drops queued work. Station
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
  ActivityKit updates and ends now share a per-Activity operation chain, so a
  refresh, replacement, automatic expiry, and user stop preserve submission order
  without serializing unrelated activities. An end marks its Activity ID terminal
  immediately: later updates and restoration ignore it, while Station Detail
  retains explicit stop intent until ActivityKit stops reporting the old session
  and clears local tracking when the system ends a session independently.
  Station Detail now treats the favourite repositories as the source of truth:
  station and route state reload after local mutations and the existing
  cross-tab change notifications, so a preserved navigation stack cannot display
  or invert stale Saved state.
  `MonitorService` now carries regular/forced intent and a generation in each
  station or traffic-info in-flight entry. A forced caller behind regular work
  receives one serial forced successor even when the regular request fails;
  equivalent forced callers still coalesce, cache publication completes before
  the tracked task resolves, and an older waiter cannot erase a newer successor.
  Reminder management now has one MainActor-owned state model: overlapping system
  snapshots coalesce, deletion/cancel-all revisions reject older snapshots, and
  cancelled loads cannot publish late state or restore removed reminders. Widget
  fetch throttling is scoped to the canonical selected-route set, so refreshing
  one widget configuration cannot suppress another configuration's first fetch;
  empty configurations do not consume the throttle or advance cache freshness.
  Timeline scheduling now covers all three departures that widget layouts can
  render, so the third countdown cannot remain at zero until the next network
  refresh. Departure and removal boundaries are evaluated independently, so a
  cached departure already rendering as `now` still receives its future removal
  entry instead of lingering until that refresh. A fresh API or app-synced
  departure delivered as `0` receives the same one-minute removal boundary.
  Authorized location failures now leave Home in an explicit retryable state
  instead of an indefinite locating placeholder; retained coordinates still win
  over a transient refresh error, and a new request clears the displayed error.
  Destructive Saved-route removal now uses an explicit idempotent repository
  operation, so a stale visible row cannot silently restore a route that another
  view already removed.
- Verified quality: Xcode static analysis passes; compiler output contains 237 app
  and 27 widget Localizable source keys, all covered by the committed 267/32-key
  catalogues with 0 missing or empty German values. Both repository structural
  validators, `git diff --check`, and the scoped secret/new-endpoint scan pass.
- Infrastructure limitation: `bash scripts/ci.sh` reaches the permission matcher
  and exits 127 because the required global `opencode` CLI is not installed.
  The reliability script's Python and timeout fixtures pass before the same
  missing-tool boundary. Hosted Quality run `30781954511` supplied the pinned CLI
  and passed the complete wrapper at exact published head
  `c147d430f53f2932da99932d5c2bb49a35f39b13`.
- Handoff: draft PR #15 tracks `codex/system-surfaces-readiness` against protected
  `main`. The live PR head/check is authoritative for remote parity because a
  static state snapshot cannot record the CI result of the commit containing
  itself; each published update must pass its own protected validation.
- The current slice passes its local gates; protected CI remains the publication
  authority. Broader product improvement remains active; do not merge or release
  without explicit approval.
- Warm-link Simulator acceptance reproduced the stale Stephansplatz detail and
  verified that `trafficvienna://search` now returns to the Discover root; paired
  before/after screenshots were inspected at 368×800.
- Home Screen widget acceptance reproduced a legacy stale payload reporting only
  about two minutes since its projection anchor, then verified the corrected
  medium widget reporting the roughly 23-minute source age while its departure
  countdown continued updating. A fresh small-widget render also confirms that
  an empty selection shows the truthful `No favourites yet` state without
  placeholder content or clipping. A second current small-widget render shows a
  real N38 route with all three countdowns visible and no clipping after the
  departure-boundary correction. A deterministic cached-row fixture then showed
  `now` and removed it 34 seconds later, before the five-minute network refresh;
  a final screenshot confirmed that live N38 data was restored.
- Focused iPhone 17 UI acceptance opened Stephansplatz, started Lock Screen
  tracking, observed the stop action, and stopped the Live Activity successfully.
  Automated overnight coverage now performs the same start/stop journey at the
  24-hour Schwedenplatz hub instead of depending on Stephansplatz service hours.
  A fifth UI journey preserves Schwedenplatz detail across a Saved-tab removal
  and proves its station star reconciles immediately; paired before/after
  screenshots show the filled and cleared states.
  Current 368×800 screenshots also confirm reminder management and the Saved
  commute/line hierarchy after their respective state-ownership refactors.
- Current iPhone 17 audit screenshots show the retryable Home location failure in
  light and dark appearance and the recovered live Stephansplatz departures after
  a successful retry, with no clipping at the standard content size.
- External release gates: distribution signing, App Store Connect processed build,
  and signed physical-device TestFlight acceptance are not provided by Simulator
  evidence.
