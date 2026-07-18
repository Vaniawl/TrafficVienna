# Architectural Decisions

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
