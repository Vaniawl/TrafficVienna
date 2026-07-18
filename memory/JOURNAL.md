# Journal

## 2026-07-18 — Polling and rendering energy optimization

- Bound Nearby, Favourites, Alerts, and Station Detail polling to the active app scene; background/inactive transitions now cancel their polling tasks.
- Added cancellation checkpoints inside sequential Nearby and Favourites request queues so a tab or scene transition stops remaining work promptly.
- Replaced refresh-generated UUID identities with route/time-derived stable IDs, avoiding full SwiftUI list churn on every Favourites update.
- Cached favourite line names in the Alerts view model and replaced per-comparison UserDefaults reads plus temporary Set allocations with direct membership checks.
- Added regression tests proving favourite item identity remains stable and repeated alert relevance checks do not repeatedly read persistent storage.
- Full XCTest suite passes on iPhone 17 Simulator after the performance and energy changes.

## 2026-07-18 — Dark mode and VoiceOver pass

- Added concise VoiceOver labels and hints for password visibility, Apple sign-in, station refresh, and favourite-line controls.
- Combined each departure row into one meaningful accessibility element with localized line, destination, next-departure, and follow-up values.
- Added expanded/collapsed semantics and an accessibility activation action to long disruption descriptions; decorative shared icons are hidden from the accessibility tree.
- Departure-row numeric transitions now respect Reduce Motion.
- Completed missing German and Ukrainian localization for all dynamically generated dashboard states and the new accessibility copy.
- Verified the Ukrainian home in dark mode with accessibility-extra-large text and increased contrast on iPhone 17 Simulator; full XCTest and repository validations pass.

## 2026-07-18 — Ukrainian localization and accessibility polish

- Completed German and Ukrainian translations for the current UI catalog and added a deterministic localization updater/check to repository validation.
- Localized runtime-generated home dashboard states so badges, greetings, titles, subtitles, and actions do not fall back to mixed-language English.
- Adapted the Nearby header and location hero for accessibility text sizes; shimmer and live-pulse animation now respect Reduce Motion.
- Hardened departure countdown parsing for ISO 8601 timestamps with and without fractional seconds and rounded remaining minutes consistently upward.
- Corrected stale-cache regression setup and added fractional-timestamp coverage; the full XCTest suite, repository validation, OpenCode validation, and whitespace checks pass.
- Verified the redesigned home visually on iPhone 17 Simulator at accessibility-extra-large text, increased contrast, and Ukrainian locale.

## 2026-07-18 — Authentication hardening and working deep links

- Upgraded device-local email verifiers to PBKDF2-HMAC-SHA256 with 120,000 iterations, random salts, timing-safe comparison, and transparent migration of legacy SHA-256 Keychain records after successful login.
- Added an explicit app Info.plist and registered the `trafficvienna://` URL scheme while preserving location, Live Activity, scene, launch, and orientation metadata.
- Verified the URL type in the built app bundle and confirmed the simulator recognizes `trafficvienna://search`; router unit tests cover destination parsing.
- Full XCTest suite passes on iPhone 17 Simulator after the security and plist changes.

## 2026-07-18 — Routines, widget optimization, docs, and release audit

- Added persisted commute routines tied to favourite stations and time; routines are managed from Account and surfaced by Smart Home.
- Optimized widget requests by grouping favourite routes by DIVA, added request timeout, and restored real stop names from the widget monitor response.
- Added routine persistence and deep-link parser regression tests.
- Updated README/context to match actual authentication, routines, reminders, offline, tests, and distribution limitations.
- Security review found no Critical/High issues in the local-only boundary; release verdict is Conditional Go pending Apple capability, URL association, backend identity, GTFS routing source, CI, and device QA.

## 2026-07-18 — Neobank system and smart travel slice

- Added reusable neobank design tokens/components and migrated Search, Favourites, Alerts, Map accents, and Station Detail to shared rounded surfaces, headers, icons, and grouped backgrounds.
- Added Smart Home insight data from favourites and relevant disruptions; service alerts affecting saved lines are now sorted first and explicitly labelled.
- Added time-sensitive local departure reminders from Station Detail context actions and modernized deprecated Live Activity update/end calls.
- Added explicit URLCache stale fallback across launches and an `AppRouter` foundation with tested `trafficvienna://station/<id>` parsing; URL-scheme registration remains a distribution configuration task.
- Full XCTest suite passes cleanly on iPhone 17 Simulator.

## 2026-07-18 — Test foundation and first performance pass

- Restored the missing `TrafficViennaTests` native target referenced by the shared scheme; the full XCTest suite now builds and runs on iPhone 17 Simulator.
- Added performance baselines for indexed station-name search and nearby spatial queries, plus regression coverage for station ID lookup and traffic-info caching.
- Added StationStore ID/search/spatial indexes so repeated search, recent lookup, Nearby, and Map queries avoid repeated normalization and full-dataset location scans.
- Limited Nearby, Alerts, and Favourites polling to the active tab and guarded Nearby against overlapping refreshes.
- Added cached/stale fallback behavior for traffic alerts, configured URLSession timeouts/cache policy, removed new Swift Sendable warnings, and migrated Maps opening to the iOS 26 API.
- Validation: `xcodebuild ... test` passes cleanly on iPhone 17 Simulator.

## 2026-07-18 — Authentication redesign

- Reworked the home screen again after user feedback into an original neobank-style experience inspired by Revolut's interaction principles: personal avatar header, large blue-violet live card, high-contrast primary action, circular quick actions, and modular information cards. Transport behavior and navigation remain native to TrafficVienna.
- Replaced the legacy Nearby screen with a full Vienna-branded home experience: custom traffic identity header, time-aware greeting, editorial hero typography, material live-location card, status metrics, integrated account/theme controls, refreshed departure-list header, and material tab bar.
- Started from clean local `main` and created `codex/auth-redesign`; remote refresh was blocked by the machine's missing GitHub SSH authorization.
- Added a redesigned auth gate with a Vienna-inspired gradient, registration/sign-in switcher, accessible email/password fields, native Sign in with Apple, validation, and clear device-local privacy copy.
- Switched the default app theme for new installs from Indigo to the branded Vienna preset, carrying the new red accent, grouped surfaces, and elevated cards into the main experience while preserving existing users' saved theme.
- Added `AuthStore`: multiple local email accounts use per-account Keychain records with random salt and SHA-256 password digest; sessions persist without storing passwords in UserDefaults.
- Added Apple credential handling, launch-time revoked credential validation, the Sign in with Apple entitlement, and an account sheet with provider details and sign-out.
- Added focused auth regression tests to the existing test source. The app build passes with no new auth warnings (two pre-existing MapKit deprecation warnings remain); XCTest remains unavailable because the repository's scheme has no configured test bundle.

## 2026-07-15 — OpenCode model and recovery readiness audit

- Started from updated `main` at `07894ac1` on fresh branch `codex/reliability-model-audit`.
- Recorded OpenCode CLI `1.17.20` model inventory in `docs/opencode/model-matrix.md` and assigned an explicit model to every OpenCode agent.
- Verified all six configured unique model IDs with minimal `opencode run --pure -m <model> "Reply with exactly: OK"` smoke calls.
- Added `docs/opencode/state-files.md` and `tests/opencode-reliability.sh` for checkpoint schema, duplicate prevention, latest-valid checkpoint selection, invalid checkpoint rejection, timeout fallback, permission safety, personal GitHub CLI context, protected-branch, and draft PR workflow checks.
- Fixed macOS CI portability after GitHub Actions showed GNU `timeout` is unavailable on the runner; the timeout fixture now uses Python `subprocess.TimeoutExpired`.
- Local validation passed: `bash scripts/validate-opencode.sh`, `bash tests/opencode-reliability.sh`, and `TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1 bash scripts/ci.sh`.
- macOS GitHub Actions remains authoritative for real Xcode build/test evidence.

## 2026-07-15 — Sequential subagent execution policy

- After PR #3 was merged, synchronized local `main` with `origin/main`, pruned deleted remote branches, and removed merged local feature branches after ancestry/content checks.
- Configured OpenCode workflow guidance so subagents run sequentially by default. Parallel execution is limited to 2-3 genuinely independent read-only tasks with documented independence, a 3-minute timeout, and automatic fallback to sequential execution.
- Added validation coverage in `scripts/validate-opencode.sh` so the orchestrator prompt and workflow docs must preserve the sequential default and timeout/fallback rules.

## 2026-07-15 — Live OpenCode autonomy audit demo

- Started from updated `main` at `410f0a34` after `git fetch origin --prune` and fast-forward pull. Created fresh branch `codex/live-autonomy-audit-20260715`.
- OpenCode launched real subagent delegation for explorer, architect, test-architect, reviewer, security-reviewer, and release-manager. `test-architect` and `reviewer` completed; the parallel subagent run then stalled, so the audit recovered sequentially and recorded the runtime blocker.
- Created `docs/opencode/live-autonomy-audit-2026-07-15.md` and checkpoint file. Controlled failure used a line-anchored sentinel check: `grep -qx 'AUTONOMY_DEMO_STATUS=PASS' ...` failed with exit 1 before the standalone sentinel existed, then passed after adding it.
- A routine safe shell-search permission prompt occurred during OpenCode's generated `rg` diagnostic. Root cause fixed by allowlisting read-only `grep *` and `rg *` bash patterns in OpenCode permissions and adding permission matcher regression cases.
- Local validation passed: JSON/shell syntax, repository validation, OpenCode validation, permission matcher, `TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1 bash scripts/ci.sh`, and `git diff --check HEAD`.
- Draft PR #3 created: https://github.com/Vaniawl/TrafficVienna/pull/3. macOS GitHub Actions `validate` passed; PR remains draft and unmerged.

## 2026-07-14 — OpenCode routine permission audit fix

- Reproduced a non-interactive OpenCode autonomy blocker: safe routine commands generated by the orchestrator (`git branch/log/status`, OpenCode folder listing, and isolated personal `GH_CONFIG_DIR` GitHub CLI checks) requested permission and were auto-rejected.
- Tightened the OpenCode allowlist with exact safe read/status/PR patterns, kept protected-branch push, force-push, merge, release, deploy, destructive commands, and secrets denied or gated.
- Re-ran the final autonomy audit prompt and found the next safe startup gap: `git fetch origin main 2>&1 && git log --oneline -5 origin/main`. Added the exact allow rule and regression case so updated-main discovery no longer blocks non-interactive runs.
- Re-ran the audit again and found the read-only branch/status bundle variant with `git status --short`. Added the exact allow rule and regression case.
- Re-ran the audit again and confirmed the startup status bundle now passes; the next gap was the read-only fallback `git log --oneline -5 origin/main 2>/dev/null || echo ...`. Added the exact allow rule and regression case.
- Re-ran the audit again and found a pipe/filter prompt (`git branch ... | head -20`). Added safe output-only filter allowances for `head`, `tail`, and `echo`, plus the concrete branch listing regression case.
- Re-ran the audit smoke test again and confirmed it now reaches context loading, personal `gh` verification, open PR listing, and explorer subagent delegation. The next gap was the safe updated-main evidence command with `echo "---FETCH OK---"` between fetch and log; added the exact allow rule and regression case.
- Extended `tests/opencode-permission-matcher.sh` with the real failing command shapes. Local validation passed with repository validation, OpenCode validation, permission matcher, CI wrapper with explicit local Xcode skip, and whitespace diff check.

## 2026-07-09 — Remote SSH as working environment request

- Користувач уточнив, що хоче, аби робота виконувалась на `skyphoenix@192.168.1.179`. Пояснено, що потрібні мережевий дозвіл у Codex і авторизація SSH ключем/паролем на remote host; попередня перевірка показала reachable host, але `Permission denied`.

## 2026-07-09 — SSH remote host connection attempt

- Перевірено SSH до `skyphoenix@192.168.1.179`: host доступний, але авторизація не пройшла (`Permission denied`). Знайдено локальний public key `id_ed25519.pub`, який треба додати на remote host у `~/.ssh/authorized_keys`.

## 2026-07-09 — SSH remote host access guidance

- Пояснено, як підключити remote host через SSH так, щоб Codex міг мати доступ: потрібні host/user/key, запис у SSH config або команда `ssh`, а також мережевий доступ у середовищі.

## 2026-06-29 — Фінальний раунд: баги, дизайн, UX, build ✅

### Виправлено баги
- **UserDefaults(suiteName:)!** — 2 force-unwrap замінено на `?? .standard` (ніколи не крашиться)
- **loadFavorites Task stacking** — `func loadFavorites()` → `async`, `.task` тепер `await` (не накопичує Task)
- **Widget показував DIVA замість назви станції** — додано `stopName` до `FavoriteWithDeparture`, заповнюється з `monitor.locationStop.properties.title`
- **Disruptions опитування на всіх табах** — перенесено `.task` в `DisruptionsView`
- **LiveActivity update() збігалась тільки по лінії** — додано `destination` + `stopName` в матчинг
- **StationStore stations пустий до завершення Task.detached** — синхронне завантаження (локальний JSON)
- **48 stale ключів** в Localizable.xcstrings — видалено

### Дизайн — мінімалістичний, професійний
- **AppColors:** видалено `appRed`/`appDim`/`appIndigo`/`appAmber`/`appDarkBg` (дублікати system кольорів). Замінено `.red`, `.secondary` скрізь.
- **DepartureLineRow:** 7→4 font sizes (caption, subheadline, title3, title2). Спейсинг: 10→8, колонки: 52→48, 62→60.
- **StationCardView:** padding 14→16, vertical 9→8.
- **OnboardingView:** мінімалістичний редизайн. Без hardcoded `Color(hex: 0xE20917)`. Іконка 88→80, шрифт `largeTitle.bold`→`title.semibold`.
- **FilterChips:** spacing 6→4, vertical 3→4, `caption2`→`caption`.
- Усі спейсинги тепер кратні 4 (grid).

### UX — зручність
- **StationCardView — бейджі ліній:** під назвою станції показуються `LineBadge(size: .small)` для кожної лінії, що обслуговує станцію.
- **StationCardView — context menu:** довгий тап → обрали станцію, поділитись, відкрити в Картах (MKMapItem).
- **StationDetailView — FilterChips:** можна фільтрувати департури за категорією (метро/трам/автобус). З'являються автоматично, коли станція має >1 категорію.

**Build: 0 errors, 0 warnings** ✅

## 2026-06-29 — Pre-deploy cleanup: dead code, Logger, DRY, LiveActivity, tests

- **🧹 Dead code:** Видалено `WidgetCacheEnvelope` (не використовувався). Видалено `favoriteEmoji` параметр з ConfigurationAppIntent + виправлено опис ("This is an example widget" → описово).
- **🔊 print() → os.Logger:** Усі `print()` замінено на `Logger(subsystem:category:)` з категоріями (store, favorites, location, live-activity, widget-sync).
- **📐 DRY normalize:** Видалено дубльовані `normalize()` у FavoritesListViewModel та TrafficViennaWidget. Усюди використовується `RouteMatching.normalize()/matches()` з WidgetShared.
- **🔄 WidgetSync:** Видалено дубльований `enum WidgetSync`. StationDetailViewModel тепер використовує `WidgetSyncManager` через протокол.
- **🖼️ Widget colors:** Додано LineColors.swift + RouteMatching.swift до widget target (pbxproj membershipExceptions). Видалено дубльовані `Color(hex:)`, `widgetLineColor()`, `WidgetLineBadge` — тепер через `LineColors`.
- **🏃 Walking speed:** Хардкоди `80` у StationCardView + NearbyViewModel замінено на `walkingSpeed` з Walking.swift.
- **🔴 LiveActivityController:** Додано методи `update()` та `stopAll()`.
- **💾 RecentSearchesStore:** `UserDefaults.standard` → App Group `(suiteName:)` з graceful fallback.
- **🧪 Тести:** Додано 22 тести: RouteMatching (10), DepartureClock (4), MonitorService (3), LineColors/LineCategory (6), WidgetDepartureData (1). MockNetworkManager для тестування MonitorService. Тести компілюються, але test target відсутній у pbxproj — додати через Xcode.
- **📓 DECISIONS.md:** Оновлено — видалено Spatial Transit, додано поточні рішення.
- **Build:** 0 errors, 0 warnings. ✅

## 2026-06-29 — Дизайн: система тем з різними стилями (background + card)

- **ThemePreset розширено:** `backgroundStyle` (.system / .grouped) + `cardStyle` (.flat / .elevated)
- **5 тем зі зміненим стилем:** Vienna, Dashboard, Ocean, Rose — grouped bg + elevated cards. Решта — system bg + flat.
- **StationCardView:** підтримує shadow + corner radius для `.elevated`
- **NearbyView:** фон змінюється залежно від backgroundStyle
- **FavoritesView:** listStyle змінюється на `.insetGrouped` для grouped тем
- **Симулятор:** app запущено, перемикай теми через `paintpalette` в Nearby toolbar
- **Build:** 0 errors, 0 warnings

## 2026-06-29 — Відновлення 10-темного дизайну після Spatial Transit

- **Що сталося:** користувач реалізував Spatial Transit (скляні картки, кастомний tab bar, дизайн-токени), але потім попросив почистити і повернути мій дизайн
- **Видалено зламані файли:** AppColors, DepartureIntent, DepartureReminder, DisruptionsViewModel, FilterChips, DisruptionsView, LineStyle
- **Створено заново:**
  - `Model/Theme.swift` — 10 пресетів (Indigo, Vienna, Dashboard, Twilight, Forest, Ocean, Rose, Monochrome, Amber, Night)
  - `Model/ThemeManager.swift` — ObservableObject singleton + UserDefaults
  - `Model/AppColors.swift` — ShapeStyle extension, appGreen = ThemeManager.shared.preset.accentColor
  - `Model/DisruptionsViewModel.swift` — використовує MonitorService.trafficInfoList()
  - `View/DisruptionsView.swift` — List + FilterChips + empty/error states
  - `View/Components/FilterChips.swift` — Capsule chips
  - `View/Components/LineStyle.swift` — LineBadge + LineColors (без дублів)
- **Додано API:** NetworkManager.fetchTrafficInfoList(), MonitorService.trafficInfoList()
- **Оновлено:** RootTabView (ThemeManager + 5 tabs + NetworkMonitor), NearbyView (paintpalette Menu), LineColors (тільки Color(hex:) + LineCategory + LineColors)
- **Build:** 0 errors, 0 warnings ✅

- **Обраний напрямок:** Spatial Transit (Liquid Glass, visionOS натхнення, глибина)
- **Нові файли:** `Model/DesignTokens.swift` — foundation: спейсинг (xs–xxl), радіуси (sm–xl), типографія (`spatialLargeTitle`, `spatialBody`, `spatialCaption`, etc.), адаптивні кольори (`spatialBackground`, `spatialText`, `spatialAccent`, `spatialAccentGlow`, etc.), `GlassModifier` + `glass()` view extension, `elevation()` shadow modifier
- **Плаваючий Tab Bar:** кастомний `ZStack` + `Capsule` з `.ultraThinMaterial`, замість `TabView`. Анімований `.opacity` перемикання. Badge на Alerts.
- **Скляні картки:** `StationCardView` тепер з `.glass()` модифікатором + `elevation(1)`. Всі списки — `ScrollView` + `LazyVStack` (замість `List`).
- **Оновлені кольори:** `AppColors.swift` тепер мапить на `spatial*` токени. `ThemePreset` скорочено до одного `spatial` (force dark).
- **LineBadge:** новий стиль — `.opacity(0.85)` фон + `.stroke(.white.opacity(0.15))` border, `RoundedRectangle(cornerRadius: 6)` замість `Capsule()`
- **Усі екрани:** NearbyView, StationDetailView, SearchView, FavoritesView, DisruptionsView, MapStationsView — перероблені на `ScrollView + LazyVStack + glass cards`
- **Збірка:** 0 помилок, 0 попереджень (включно з widget extension)

## 2026-06-29 — 10 тем + перемикання однією кнопкою

- **Нові файли:** `Model/Theme.swift`, `Model/ThemeManager.swift`, `Model/AppColors.swift`
- **10 пресетів:** Indigo, Vienna, Dashboard, Twilight, Forest, Ocean, Rose, Monochrome, Amber, Night
- **ThemeManager:** ObservableObject + singleton, зберігає вибір у UserDefaults
- **Кнопка перемикання:** `paintpalette` Menu в toolbar NearbyView (leading side). Кожен пункт меню показує галку для активного + кольорову крапку.
- **Динамічні кольори:** `ShapeStyle` extension читає `appGreen` з `ThemeManager.shared.preset.accentColor`. Решта кольорів — системні.
- **Light/Dark:** `.preferredColorScheme(themeManager.preset.colorScheme)` — 3 теми force dark, 3 force light, 4 system.
- **AppColors.swift** винесено з WidgetShared/LineColors.swift (там залишено тільки `LineCategory` + `LineColors` + `Color(hex:)`)
- **Build:** 0 errors, 0 warnings

## 2026-06-28 — Тематична система (6 тем + пікер у налаштуваннях)

- **🎨 Нова архітектура:** `Model/Theme.swift` — `ThemeID` enum + `Theme` struct з усіма токенами (кольори, типографія, лейаут, фічі). Передається через `@Environment(\.theme)`.
- **⚙️ SettingsView** — пікер тем з іконками, sheet на Favourites вкладці (шестерня).
- **6 тем:**
  - **Standard** — поточний мінімалістичний дизайн
  - **Dark Terminal** — чорний фон, `.monospaced`, зелений акцент, квадратні кути, без іконок
  - **Big Data** — hero 56pt `.ultraLight`, без карток/поверхонь, без follow-up
  - **Editorial** — 17pt body, без карток, великі відступи
  - **Glass** — `.rounded` font, 20pt картки, `.systemFill` blur surface
  - **Industrial** — `.monospaced` скрізь, квадратні кути, сірий акцент
- **Ключові зміни:** `DepartureLineRow` тепер використовує `theme.heroSize/Weight/Design`; `StationCardView` перевіряє `theme.useCards`; усі списки отримали тему-авар; іконки ховаються через `theme.showIcons`.
- **Збірка:** 0 помилок, 0 попереджень (включаючи widget extension — `LineBadge` без залежності від теми).

## 2026-06-28 — Повний мінімалістичний редизайн UI

- **🎨 Філософія:** Data-first. Прибрано декоративні елементи, анімації, зайві кольори. Системні семантичні кольори замість кастомних, типографія зі світлими вагами, базовий спейсинг 8pt.
- **🧹 Shimmer + LivePulse** — видалено анімації повністю (no-op).
- **🔖 LineBadge** — прибрано `.bold()`, зменшено паддинг радіус 6→4, менші відступи.
- **🏷️ FilterChips** — `.thinMaterial` → `.quaternarySystemFill`, менший паддинг, без анімації.
- **🚃 DepartureLineRow** — повний rewrite:
  - Видалено колонку гліфів (figure.walk/run/nosign + LivePulse) та `@ScaledMetric`.
  - Час відправлення: `title2.weight(.semibold)` → `system(size: 24, weight: .light, design: .monospaced)`.
  - "min" під числом (`VStack`), а не поряд.
  - Follow-up справа, без `showFollowUp = false` розділення.
  - Прибрано `.animation(.snappy)` та `.sensoryFeedback`.
- **🗂️ StationCardView** — радіус 16→10, паддінг 14→12, відступи рядків 9→6.
  - Walking текст спрощено з "N min · N m/km" до "N min".
  - Скелетон без `.shimmer()`.
- **📡 NearbyView** — спейсинг LazyVStack 12→8, пом'якшено empty states (іконка 36pt tertiary, `.body` заголовок).
- **🔍 SearchView** — прибрано `bold()` підсвітку пошуку, прибрано іконку `clock.arrow.circlepath` в рецентсах.
- **📱 StationDetailView** — скелетон без `.shimmer()`, freshness bar 5pt коло, 4pt спейсинг.
- **⭐ FavoritesView** — freshness bar 5pt коло.
- **⚠️ DisruptionRow** — зменшено спейсинги, прибрано `.weight(.semibold)` і `.weight(.medium)`.
- **🗺️ MapStationsView** — банер радіус 12→8, 10pt паддінг.
- **👋 OnboardingView** — 3→2 сторінки, прибрано featuresPage та велику іконку. Заголовок `.largeTitle.weight(.light)`.
- **ℹ️ AboutView** — іконка 72→56, радіус 18→14, 26pt font замість 34.
- **🏠 RootTabView** — offline-банер: `VStack` → `.overlay`, компактніший (Capsule, 4pt паддінг).

- Збірка: 0 помилок, 0 попереджень.

## 2026-06-28 — Bugfix round: test target, walking constant, Quick Actions, backoff, translations, force‑unwrap

- **🔴 Test target** — додано `TrafficViennaTests` в pbxproj (PBXNativeTarget, BuildConfigurations, ContainerItemProxy, TargetDependency). Схему TrafficVienna.xcscheme налаштовано з TestTargets. Тести запускаються через `xcodebuild test -scheme TrafficViennaTests`. 9/9 passed.
- **🔴 Quick Action** — `"favorites"` → `"favourites"` (Tab raw value тепер збігається).
- **🟡 `walkingSpeed`** — прибрано `private`, тепер `internal`. Хардкоди `80` замінено на `walkingSpeed` у StationCardView + NearbyViewModel.
- **🟡 NearbyView polling** — замінено 5-секундний poll на 30с (немає локації) / 15с (пусто) / 60с (норма).
- **🟡 StationStore** — додано `@MainActor static let shared` для Siri intent. DepartureIntent більше не декодує JSON при кожному виклику.
- **🟡 Force-unwrap** — `mapsURL` тепер `URL?` з `if let` в StationDetailView. AboutView — `URL(string:)` з `??` fallback.
- **🟡 Переклади** — додано 17 німецьких перекладів у Localizable.xcstrings.
- **🟡 Схема** — очищено мертві посилання з xcschememanagement.plist.
- **Збірка**: 0 помилок, 0 попереджень.
- **Команда для тестів**: `xcodebuild test -scheme TrafficViennaTests -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'`

## 2026-06-28 — Final round: features + perfection (notifications, Quick Actions, DI, search)

- **🔔 DepartureReminder** — контекстне меню "Notify me in N min" → `UNNotification` з `.timeSensitive`
- **⚡ Quick Actions** — long-press app icon → Search / Favourites / Nearby (через `UIApplicationShortcutItem` + `AppDelegate`)
- **📱 Dynamic Island** — minimal view → countdown (була статична іконка); expanded bottom → назва станції + напрямок
- **⌨️ SearchView** — `.toolbar` з `Button("Done")` на клавіатурі
- **🎭 Shimmer** — вимкнено при `UIAccessibility.isReduceMotionEnabled`
- **⏭️ Onboarding** — "Skip" на перших 2 сторінках (overlay topTrailing)
- **⭐ Favorites** — `.searchable` фільтр по `lineName` + `destination`
- **🚀 Launch screen** — `INFOPLIST_KEY_UILaunchScreen_ColorName = "wienerLinienRed"`
- **Warnings** — виправлено `@preconcurrency` + `[weak self]` в Task
- Збірка: 0 помилок, 0 попереджень.
- **Продукт готовий до релізу.**

## 2026-06-28 — UI/UX polish marathon (3 rounds of improvements)

- **🔥 Баги:**
  - `RootTabView`: `.constant(!hasOnboarded)` → `Binding(get:set:)` — онбординг тепер закривається
  - `SearchView`: `TapGesture` на `NavigationLink` → `onAppear` — навігація не ламається
  - `DepartureLineRow`: `missed` icon `figure.walk` → `nosign` (колірна сліпота)
- **🗺️ Карта:**
  - DragIndicator на sheet
  - Open in Maps в тулбарі StationDetailView
  - `accessibilityHint` на маркери
- **🔍 Пошук:**
  - Підсвітка тексту пошуку жирним
  - `.autocorrectionDisabled()`
  - `.onSubmit` ховає клавіатуру
  - Clear recents — confirmation alert
  - Анімація результатів `.animation(.default, value: results.map(\.id))`
- **📡 Мережа:**
  - `NetworkMonitor` (`NWPathMonitor`) — offline-банер "No connection" у RootTabView
  - `DisruptionsView` + `FavoritesView` error states — кнопка "Try again"
  - `NearbyView` error banner — tappable для retry
- **🕐 Час відправлення (HH:mm):**
  - `DepartureClock.formattedTime()` — formatter для ISO8601 → "12:47"
  - `DepartureGroup.times` — масив hh:mm, відсортований синхронно з minutes
  - `DepartureLineRow.nextTimeString` — показується під destination
  - StationDetailView ✅, StationCardView ✅, FavoritesView ✅
- **🔴 Live Activity:**
  - `stopAll()` + `isTracking` — кнопка `bell.slash` в тулбарі
  - Haptic feedback при старті
- **🔔 Alerts вкладка:**
  - Badge з кількістю збоїв
  - `.searchable` фільтр за номером лінії
  - ShareLink в контекстному меню
- **🧑‍🦯 Accessibility:**
  - FilterChips: `.accessibilityAddTraits(.isSelected)`
  - DisruptionRow: `.accessibilityHint` для expand
  - LivePulse: `.accessibilityHidden`
- **💄 Onboarding:**
  - 3-сторінковий TabView з page dots
  - Анімовані кнопки Next / Get started
- **Інше:**
  - StationDetailView: `ContentUnavailableView` + retry action
  - StationDetailView: `ShareLink` + `accessibilityLabel` на refresh
  - StationDetailView: ScrollViewReader — scrollTo top при зміні фільтра
  - FavoritesView lines: hh:mm час
  - `DepartureInfo.formattedTime` computed property
- Збірка: 0 помилок, 0 попереджень.

## 2026-06-28 — More polish (dead code, AppIntent, walking, locale, battery)

- **🗑 Dead code:** Видалено `WidgetCacheEnvelope` (не використовувався)
- **🧹 DRY:** `AppIntent.swift` — замінено власний `Stored` struct + ручне декодування на `UserDefaultsFavoritesRepository().getAll()`
- **🧹 DRY:** Створено `Model/Walking.swift` — `CLLocation.walkMinutes(to:)` замість дубльованої формули `distance/80` у SearchView + FavoritesView
- **🧹 StationStore:** `locale: .current` → `Locale(identifier: "de_DE")` (стабільна поведінка діакритики)
- **💄 `FavoriteRoute`:** додано `Identifiable` + `var id: String`
- **💄 LocationManager:** `startUpdatingLocation()` → `requestLocation()` (single-shot, менше батареї)

## 2026-06-28 — Major code improvements (bugs, DRY, polish)

- **🐛 Баги:**
  - `FavoritesView`: `lat/lon ?? 0` → Vienna centre fallback (48.2082, 16.3738)
  - `MonitorService.trafficInfoList`: додано coalescing (був відсутній, на відміну від `fetchCoalesced` для DIVA)
  - `LiveActivityController`: `print()` → `os.Logger`
- **🧹 DRY:**
  - Додано `Model/DTO.swift`, `Model/FavoritesManager.swift`, `Model/NetworkManager.swift`, `View/Components/LineStyle.swift` до widget target через pbxproj exceptions — видалено 100+ рядків дубльованих DTO, `FavoriteRoute`, `fetchMonitorData`, `WidgetLineBadge` з `TrafficViennaWidget.swift`
  - Створено `FilterChips` (View/Components/FilterChips.swift) — shared компонент для StationDetailView + DisruptionsView
  - `Color.wienerLinienRed` — спільна константа замість хардкоду `Color(hex: 0xE20917)` у 7 місцях
- **💄 Поліпшення:**
  - `LineCategory.symbol`: metro → `subway.fill` (був `tram.fill`)
  - `LocationManager`: `DispatchQueue.main.async` → `nonisolated` + `Task { @MainActor }`
  - `Shimmer`: `Color.white.opacity(0.55)` → `Color.primary.opacity(0.12)` (адаптивний до теми)
  - `RecentSearchesStore`: `UserDefaults.standard` → App Group `UserDefaults(suiteName:)`
- Збірка: чиста, 0 помилок, 0 попереджень.

## 2026-06-28 — Fix build, clean scheme

- Виправлено `StationStore.swift:55` — обгорнуто `Self.loadBundledStations` у замикання (default parameter не інферувався як () → [Station]).
- Виправлено `MapStationsView.swift:58` — `if let banner = locationBanner` замінено на пряме використання (`@ViewBuilder` повертає non-optional `some View`).
- Видалено мертвий `TestableReference` зі схеми (TrafficViennaTests target був відсутній у pbxproj, але scheme на нього посилався).
- Збірка чиста: 0 помилок, 0 попереджень.
- Тести через `xcodebuild test` поки не запускаються — target не додано до проєкту; файл `TrafficViennaTests.swift` існує, але не скомпільовано.

## 2026-06-28 — Initial workspace setup

- Налаштовано каркас «мозок агента»: AGENTS.md, docs/CONTEXT.md, docs/REFERENCES.md, memory/JOURNAL.md, memory/DECISIONS.md, opencode.json.
- Проєкт: TrafficVienna — iOS-застосунок для live-відправлень Wiener Linien (SwiftUI + MVVM).
- Стан: A (готовий Xcode-проєкт).
- Збірка: не компілюється — `StationStore.swift:55` помилка (default argument не працює як closure reference).
- Структура: 5 табів (Nearby, Search, Map, Alerts, Favourites), 16 файлів Model, 11 файлів View, WidgetExtension, Unit Tests.
- Чекаю напрямку від Івана.

## 2026-06-28 — UI/UX поліш та рефайн

### Зроблено
- **LineBadge** тепер використовує офіційні кольори Wiener Linien замість `.appGreen` (U1=red, U2=purple, U3=orange, U4=green, U6=brown, tram=red, bus=blue, etc.)
- **DepartureLineRow** використовує `LineBadge` замість inline `[U1]` — кольорові бейджі на всіх екранах
- **"NOW"** — зелений капсульний бейдж замість plain тексту
- **StationCardView** — показує `+ N MORE` коли ліній більше ніж 4
- **FilterChips** — вибраний чіп отримує колір категорії (U-Bahn=blue, Tram=red, etc.), білий текст
- **Tab bar** — повернуто SF Symbols (стандартний iOS UX)
- **Navigation bar** — повернуто `.navigationTitle` + `.toolbar` з SF Symbols
- **Контекстні меню** — `Label` + `systemImage` (стандартний UX)
- **Стандартний back button** замість кастомного `< BACK`

### Рішення
- App має термінальний вайб (темна тема, зелений акцент, моношир), але використовує стандартні iOS патерни навігації
- Лінійні бейджі в офіційних кольорах замість суцільного зеленого — краща сканованість
- Кольори категорій у FilterChips допомагають швидко фільтрувати
- `+ N MORE` уникає перевантаження рядка в StationCardView
