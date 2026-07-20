# Architectural Decisions

## 2026-07-20 — Capability-isolated Personal Team Debug builds

**Context:** Free Apple Personal Teams cannot provision Sign in with Apple or App Groups, so the production app and embedded widget could not be installed on a developer's physical iPhone even though simulator builds worked.

**Decision:** Give the existing Debug configurations unique development bundle identifiers and separate empty entitlement files for both the app and widget. Keep the Release identifiers and production entitlement files unchanged. Continue selecting the signing team locally in Xcode rather than committing a personal team identifier.

**Consequences:** A Personal Team can install Debug builds and exercise device-local email authentication plus the main app. Sign in with Apple and cross-process widget synchronization remain unavailable in that build because those capabilities require a paid team. Release continues to carry the production Sign in with Apple and App Group declarations; reverting the Debug build-setting changes restores the former single-capability configuration without migrating user data.

## 2026-07-19 — Allowlisted local travel-data export

**Context:** A privacy-focused app should let users inspect and retain their local profile and travel preferences, but a raw dump of app storage could expose password verifiers, provider identifiers, runtime caches, or implementation-only keys.

**Decision:** Export a versioned, explicit Codable snapshot containing only provider name, optional email/display name, safe appearance/Home/App Lock preferences, ordered favourite stations and routes, commute routines, and recent station identifiers. Exclude the authentication `userID`, Keychain material, tokens, live API/cache state, widget internals, and location history. Generate pretty-printed JSON in memory and hand it to SwiftUI's system file exporter so the user chooses the destination. Restore only schema version 1 after a 1 MB size cap and strict value/count validation; normalize duplicates, require explicit destructive confirmation, ignore account/App Lock fields, apply through root-owned stores, verify the resulting snapshot, and reapply a pre-restore snapshot on verification failure.

**Consequences:** The format is deterministic, testable, readable without TrafficVienna, and can evolve through `schemaVersion`. Exported files contain personal data and become the user's responsibility after the system save/share action. Restore is idempotent and cannot replace credentials or weaken app-lock security, but intentionally replaces the confirmed local appearance/Home/travel state. Adding a new field requires an explicit privacy review, restore allowlist/test update, and schema compatibility decision; reverting the feature leaves already stored app data readable by existing stores.

## 2026-07-19 — Device-owner authentication for optional app lock

**Context:** A neobank-style app lock should conceal the signed-in UI when TrafficVienna leaves the foreground, but a biometrics-only policy can strand users after lockout or enrollment changes. The app must not receive or persist biometric material.

**Decision:** Keep app-lock state in a root-owned `AppLockStore`, persist only an opt-in boolean and selected timeout in app-local defaults, and delegate verification to `LocalAuthentication`. Require an enrolled biometric to enable the feature, then evaluate `deviceOwnerAuthentication` for unlocking so the operating system can fall back to the device passcode. Immediately replace the signed-in UI with a privacy shield whenever the scene becomes inactive, but allow identity verification to be deferred by zero, one, or five minutes using monotonic system uptime. Retain heavy model owners in a signed-in-session `RootTabState`.

**Consequences:** Face ID, Touch ID, and Optic ID remain system-controlled, failed or cancelled attempts never expose the signed-in UI, and biometric changes do not create an unrecoverable lock. Private UI, modal presentation, and polling disappear immediately even during a grace period, while prepared station indexes, cached view models, and selected-tab state survive unlock. Cold starts remain locked, and wall-clock changes cannot extend an in-process timeout. This is a local privacy barrier rather than server authorization or encryption of the underlying device data.

## 2026-07-18 — Allowlisted travel-data reset distinct from identity removal

**Context:** Travel preferences and runtime artifacts span App Group repositories, recent-search state, widget metadata, notifications, Live Activities, and monitor caches. They are device-level data rather than records owned by the current local authentication identity.

**Decision:** Keep identity removal and travel-data reset as separate confirmed actions. Implement travel reset with an explicit key and side-effect allowlist, shared root-owned UI stores, targeted `departure.*` notification removal, TrafficVienna activity termination, and monitor cache clearing. Preserve auth, theme, onboarding, permissions, and bundled reference data.

**Consequences:** Users can erase their travel history/preferences without losing sign-in access, and can remove a local identity without unexpectedly destroying travel setup. The reset is idempotent and testable; future user-generated stores must be deliberately added to the allowlist and reset verification.

## 2026-07-18 — Provider-aware local account removal boundary

**Context:** Device-local email registration created a persistent Keychain password verifier, but Sign out removed only the active session. Sign in with Apple stores no app-owned credential that TrafficVienna can revoke, and there is no authentication backend.

**Decision:** Expose a confirmed “remove account from device” flow. For email identities, delete the exact hashed Keychain account record and clear the session only after deletion succeeds. For Apple identities, clear only the local session and explicitly state that the Apple ID is not deleted or revoked. Keep favourites and routines because they are device-level travel preferences rather than per-identity records.

**Consequences:** Users can remove local email credentials without reinstalling the app, deletion failures are retryable without losing session access, and Apple behavior is not overstated. A future server-backed identity provider must replace this operation with its own authenticated account-deletion and token-revocation workflow.

## 2026-07-18 — Ordered line-favourite persistence and shared UI ownership

**Context:** Line favourites were persisted as a Set. Converting that Set to an array produced nondeterministic Favourites and widget ordering, while each Station Detail heart decoded the same JSON independently. Alerts also cached a separate view of the saved lines.

**Decision:** Persist line favourites as a duplicate-normalized array in insertion order and make the root-owned `FavoritesListViewModel` the UI source of truth. Keep the repository as the App Group persistence boundary, decode the same ordered array in the widget, and push route changes into the Alerts view model.

**Consequences:** Heart state, Favourites, personalized Alerts, and widget route priority remain consistent without per-row storage reads. Existing Set payloads decode as arrays because their JSON representation is already an array; older builds can decode the new array as a Set, so migration and rollback are non-destructive.

## 2026-07-18 — Backward-compatible minute precision for commute routines

**Context:** The routine DatePicker accepts hours and minutes, but persisted routines stored only `hour`, silently changing values such as 08:45 to 08:00. Existing installations may already contain the original JSON schema in the shared App Group.

**Decision:** Add a `minute` field while retaining `hour`. Decode a missing minute as zero, continue encoding the legacy hour key, and select the nearest enabled routine using circular minute-of-day distance.

**Consequences:** Existing routines load without a destructive migration, new schedules preserve the user’s exact selection, and midnight comparisons are correct. Older app builds can still decode newly written records because Codable ignores the additional minute key, providing a safe rollback path.

## 2026-07-18 — Versioned App Store metadata without aspirational claims

**Context:** App Store copy must remain consistent across three localizations and must not imply route planning, ticketing, cloud identity, or recovery that the local-first app does not implement. Required URLs and legal/privacy facts cannot be invented from repository context.

**Decision:** Keep localized marketing copy in a machine-validated repository JSON file and keep review, privacy, screenshot, and submission guidance beside it. Enforce Apple's current field and UTF-8 keyword limits in repository validation. Represent unverified public URLs as pending and retain external privacy, content-rights, capability, legal, and screenshot work as explicit release gates.

**Consequences:** Marketing text can be reviewed and copied consistently without overstating the product. A passing repository check means the copy is structurally ready, not that external App Store conditions have been completed.

## 2026-07-18 — Per-executable privacy manifests and conservative label boundary

**Context:** The app and widget both use required-reason `UserDefaults` APIs, including a shared App Group. TrafficVienna itself keeps identity, location, favourites, and search state on device, but direct Wiener Linien API requests necessarily expose network metadata to the API operator and the repository has no API-specific retention agreement.

**Decision:** Ship a privacy manifest in each executable bundle. Declare app-only UserDefaults as `CA92.1`, shared App Group defaults as `1C8F.1`, and no tracking. Keep App Store privacy-label completion conditional on verified `ogd_realtime` IP logging and retention terms instead of inferring them from unrelated Wiener Linien web policies.

**Consequences:** Required-reason declarations are explicit, valid, and independently packaged for the app and widget. The current code-controlled privacy posture is documented, while public policy hosting and third-party API retention remain release gates rather than unsupported claims.

## 2026-07-18 — Incremental neobank architecture and external routing boundary

**Context:** The roadmap adds a unified dashboard, routines, reminders, offline behavior, sync foundations, and eventually A→B routing. A broad rewrite would put the existing realtime pipeline, widget, and Live Activities at unnecessary risk.

**Decision:** Preserve SwiftUI/MVVM and `MonitorService`; add shared neobank view primitives and small additive stores/services. Keep commute routines in the existing App Group, local reminders in UserNotifications, and offline fallback in URLCache. Do not implement A→B routing until a verified licensed GTFS/routing source is selected. Do not claim cross-device identity until a backend verifies Apple/email credentials.

**Consequences:** Current features remain compatible and independently revertible. Full routing, password recovery, account sync, and production deep-link association remain explicit integration projects rather than simulated local behavior.

## 2026-07-18 — Local-first authentication boundary

**Context:** TrafficVienna had no authentication backend or third-party auth dependency. The requested email and Apple ID registration must not imply server-backed identity or store plaintext passwords locally.

**Decision:** Add an app-level `AuthStore` gate. Email accounts are device-local: normalized account identifiers and PBKDF2-HMAC-SHA256 verifier records with random salts are stored in Keychain, while only the active non-secret session is stored in UserDefaults. Legacy salted SHA-256 records are upgraded after the next successful login. Sign in with Apple uses `AuthenticationServices`, requests only name/email, enables the Apple Sign In entitlement, and revalidates the stored Apple credential on launch. Keep the service boundary replaceable by a server-backed provider later.

**Consequences:** Registration and sign-in work safely on one device without adding a vendor dependency. Email accounts do not sync across devices and are not suitable for server-side personalization until a backend is selected. Apple capability must also be enabled for the App ID in the Apple Developer portal before device distribution.

## 2026-07-15 — Explicit OpenCode model assignment and state recovery contract

**Context:** The OpenCode workflow needs production-readable model ownership and recovery behavior. Relying on implicit/default model selection makes audits and recovery harder, and long-running autonomous work needs a deterministic state-file contract.

**Decision:** Assign every OpenCode agent an explicit model returned by `opencode models`; record the model inventory, context limits, rationale, and cost class in `docs/opencode/model-matrix.md`. Keep fallback models unconfigured until a verified OpenCode fallback field exists in local config tooling. Define repository-local state responsibilities and checkpoint schema in `docs/opencode/state-files.md`, and enforce the model/state/permission/recovery contract with `tests/opencode-reliability.sh` in CI.

**Consequences:** Agent model resolution is inspectable and testable. Recovery behavior now has explicit acceptance criteria and fixture coverage for valid, invalid, stale, interrupted, compacted, and timeout states. Future model or fallback changes must update both documentation and validation.

## 2026-07-15 — Sequential subagent execution by default

**Context:** The live autonomy audit proved that launching six subagents in parallel can stall the OpenCode run even when some subagents complete. The workflow needs predictable production behavior before broad parallelism.

**Decision:** Run subagents sequentially by default. Allow parallel execution only for 2-3 genuinely independent read-only tasks with documented independence, a 3-minute batch timeout, and automatic fallback to sequential execution for unfinished work. Never parallelize implementation, validation, commit, push, PR handoff, release, or deployment work.

**Consequences:** The MVP favors reliable autonomous completion over maximum concurrency. Parallelism remains available for small safe discovery batches, but stalls become recoverable workflow events instead of indefinite blockers.

## 2026-07-15 — Read-only shell search commands are routine OpenCode operations

**Context:** During the live autonomy audit, OpenCode generated a shell `rg` diagnostic for the controlled sentinel check. The command was read-only and repository-scoped, but it requested permission because only the OpenCode grep tool, not shell `grep`/`rg`, was allowed.

**Decision:** Allow repository-local read-only shell search patterns `grep *` and `rg *` for the orchestrator and root OpenCode configuration. Keep secret path deny rules, destructive commands, protected-branch pushes, force-push, merge, release, and deploy gates unchanged.

**Consequences:** Routine diagnostics and validation can continue without non-interactive permission dead-ends, while secret access and mutation boundaries remain protected.

## 2026-07-14 — OpenCode personal GitHub CLI permission shape

**Context:** Non-interactive OpenCode runs auto-reject permission prompts. The TrafficVienna workflow must use the isolated personal GitHub CLI context (`GH_CONFIG_DIR=/home/skyphoenix/.config/gh-personal`) for status, repository, draft PR, and PR update commands without falling back to the work account.

**Decision:** Allow exact safe personal `GH_CONFIG_DIR=... gh ...` status/repository/draft-PR command shapes and exact read-only compound discovery commands generated during the autonomy audit. Keep direct `main` pushes, force-push, merge, release, deploy, destructive commands, and secret reads denied or approval-gated.

**Consequences:** OpenCode can continue routine autonomous TrafficVienna work without permission dead-ends while preserving repository protection and identity separation.

## 2026-06-29 — Очищення та стандартизація до деплою

**Context:** Аналіз проекту виявив дубльований код, мертвий код, розбіжності в JOURNAL.md та неконсистентні патерни.

**Decisions:**
- **Logger:** `print()` → `os.Logger` з категоріями (`store`, `live-activity`, `favorites`, `location`, `widget-sync`). Локальні `private let log = Logger(...)` в кожному файлі.
- **RouteMatching** — єдине джерело правди для нормалізації напрямків. Видалено дубльовані `normalize()` у FavoritesListViewModel та TrafficViennaWidget.
- **WidgetSync** — видалено дубльований `enum WidgetSync`, залишено протокол `WidgetSyncing` + клас `WidgetSyncManager`.
- **WidgetShared** — додано LineColors.swift та RouteMatching.swift до widget target (через membershipExceptions у pbxproj). Видалено дубльовані `Color(hex:)`, `widgetLineColor()`, `WidgetLineBadge` з widget — тепер використовує `LineColors`.
- **RecentSearchesStore** — виправлено: `UserDefaults.standard` → App Group `UserDefaults(suiteName:)`. Додано graceful fallback.
- **LiveActivityController** — додано методи `update()` та `stopAll()`.
- **Walking speed** — хардкоди `80` у StationCardView та NearbyViewModel замінено на константу `walkingSpeed` з Walking.swift.
- **ConfigurationAppIntent** — видалено безглуздий параметр `favoriteEmoji`, виправлено опис.

**Consequences:**
- +1 файл (Logging.swift — але пізніше видалено на користь inline)
- -40 рядків дубльованого коду (normalize, WidgetCacheEnvelope, widget line colors)
- 0 помилок, 0 попереджень при збірці
- Всі normalization тепер консистентні (diacritic-insensitive, trailing " u"/" s" stripping)
