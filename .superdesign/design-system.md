# Traffic Vienna design system

## Product context

Traffic Vienna is a native iPhone public-transport companion for Vienna. It helps people answer three urgent questions quickly: what leaves next, whether service is disrupted, and where the nearest useful stop is. The product works without an account; favourites remain on device. Data can be live, saved, stale, unavailable, loading, or empty, and the visual language must state that honestly.

Core journeys:

1. Onboarding → anonymous entry → optional location permission.
2. Nearby dashboard → featured saved departure → service health → saved stations → nearby stations.
3. Search → recent stops or results → station detail.
4. Station detail → live departures, filters, alerts, favourite and Live Activity actions.
5. Map → explore area → select stop → station detail.
6. Alerts → search/filter → disruption detail.
7. Favourites → saved stations and routes.

## Visual direction

The approved redesign direction is premium, calm, minimal and interaction-led, inspired by the restraint and motion quality of modern fintech apps such as Revolut without copying branding, proprietary artwork, or exact screens. The supplied mobile-booking reference contributes its mint-to-green freshness, large white sheets, black primary actions, clear hierarchy, and generous rounded geometry.

The design should feel native to iOS, transit-specific, and much less like a stack of generic system cards.

### Target palette

- Brand mint: `#41C7AD`.
- Brand green: `#21B66F`.
- Brand deep: `#087A5B`.
- Ink: `#101114`.
- Pure surface: `#FFFFFF`.
- Canvas light: `#F5F6F4`.
- Soft mint surface: `#EEF9F5`.
- Primary text: `#101114`.
- Secondary text: `#656B70`.
- Tertiary text: `#969B9F`.
- Border: `#E7E9E8`.
- Success: `#18A66A`.
- Warning: `#F0A52B`.
- Error: `#DF3E4E`.
- Information: `#3478F6`.
- Line identity colors remain transport-semantic and must not be recolored to brand mint.

For dark mode use iOS semantic backgrounds and labels with brand mint lifted slightly for contrast. Never use fluorescent neon green.

### Current source palette for reproduction only

- Existing app brand: `#E20917` → `#A90712` gradient.
- Existing grouped background and card colors are iOS semantic.
- Use this layer only for the mandatory current-state reproduction. All redesign branches use the target palette above.

### Typography

- SF Pro only, using native iOS styles.
- Large navigation title: 34/41 bold where a strong destination title is needed.
- Hero metric: 40–48 semibold/bold with monospaced digits.
- Section title: 20–22 semibold.
- Card title: 17 semibold.
- Body: 17 regular.
- Supporting copy: 15 regular.
- Caption/status: 12–13 medium.
- Avoid all caps except short transport line identifiers and very small eyebrow labels.

### Geometry and spacing

- 4-point base grid; primary spacing scale 4, 8, 12, 16, 20, 24, 32, 48.
- Screen horizontal padding: 20 points on compact iPhone, 48 on regular width.
- Large hero/card radius: 24 points.
- Standard surface radius: 18 points.
- Compact row/control radius: 12 points.
- Pills and line badges: full capsule or compact rounded rectangle.
- Minimum hit target: 44×44 points.
- Prefer fewer, larger grouped surfaces over many same-weight cards.

### Surfaces

- Main canvas is warm off-white, not flat gray.
- White cards carry either a `#E7E9E8` 1-point border or a soft shadow, not both.
- Hero areas may use a restrained mint→green gradient with white content.
- Primary CTA is ink/black with white text; brand green is for selection, state, highlights and positive live indicators.
- Use bottom sheets and floating surfaces for confirmations and focused actions.
- Preserve safe areas and native tab/navigation behavior.

### Iconography

- SF Symbols only in production UI.
- Use filled icons for active navigation and strong state, outline icons for secondary actions.
- Standard sizes: 16 compact, 20 row, 24 navigation/feature, 32–44 illustration focal point.
- Icons never substitute for a line label, destination, departure time, or data-freshness text.

## Component language

### Featured departure hero

- One dominant surface at the top of Nearby.
- Small label and truthful live/saved status at top.
- Route badge + destination as the main identity.
- Countdown is the strongest metric.
- Station name and action remain secondary.
- The whole card is tappable and uses subtle press scaling.

### Service summary

- Compact horizontal row inside a white surface.
- 44-point status icon, two-line hierarchy, optional saved-data note, chevron.
- Status color is semantic; alert state must not be expressed by color alone.

### Station card

- Clear station name and walking context first.
- Transit line badges provide scanning landmarks.
- Departure rows align route, destination, and time; no decorative noise.
- Freshness appears near the header and always includes text.

### Primary action

- Ink fill, white SF Pro semibold label, 52–56 point height, 16–18 point radius.
- Press: scale to 0.985 and reduce opacity slightly over 120–160 ms.
- Disabled: lower contrast but label remains readable.

### Search

- Use a large, soft search field directly below the title.
- Recent stops should be lightweight rows, not large cards.
- Results emphasize stop name and line chips, with a subtle chevron.

### Bottom navigation

- Preserve five destinations and native iOS safe-area behavior.
- Use a clean white/translucent background and thin separator.
- Active destination uses brand green; inactive items use secondary text.
- Alert badge remains semantic red/orange and numeric.

## Screen guidance

### Onboarding

- Each page uses a large atmospheric mint/green illustration area with a single SF Symbol composition, not stock imagery.
- Copy is left-aligned, concise, and readable in one glance.
- Persistent black primary button at the bottom.
- Pager is quiet and the anonymous-use message is visible without competing with the CTA.

### Nearby

- Prioritize: next saved departure, service status, favourite stops, then nearby stations.
- Reduce repeated borders and shadows. Use section labels and whitespace for grouping.
- Add a compact greeting/context line such as current area or morning/afternoon only when data is available; never fabricate location.

### Station detail

- Treat station identity and next departure as a compact hero header.
- Keep filters horizontally scrollable and immediately reachable.
- Separate live departures from alerts with clear section rhythm.
- Favourite and refresh remain top-bar actions.

### Alerts

- All-clear state should feel reassuring, not empty.
- Active incidents use severity, affected lines, concise impact, and time/freshness.
- Search and category filters remain directly under the title.

### Favourites

- Saved stations appear as quick-entry rows/cards above route-specific departures.
- Reordering remains understandable.
- Empty state explains the two ways to save content.

## Motion and feedback

- Quick state changes: 280 ms snappy with no bounce.
- Page/sheet changes: 380 ms smooth.
- Live countdown uses numeric text transition only.
- Press feedback: 120–160 ms scale 0.985.
- Cards enter with 8–12 point upward movement plus opacity only when spatially meaningful.
- Bottom sheets rise from the bottom with opacity; selections use light haptics.
- Loading uses restrained shimmer; live state uses a subtle pulse.
- Reduce Motion removes displacement, scale, pulse, shimmer and number rolling, leaving opacity or static state.

## Accessibility and truthfulness

- Support Dynamic Type through accessibility sizes without clipping.
- Keep 4.5:1 text contrast and 3:1 meaningful control/icon contrast.
- Never communicate status by color alone.
- VoiceOver combines fragmented departure information into one useful sentence.
- Live, saved, stale and unavailable are explicit textual states.
- Do not add account, payment, ticket purchase, or booking capabilities that the product does not implement.
- Do not imitate Revolut branding, logos, copy, or financial content; borrow only interaction restraint, hierarchy and motion quality.
