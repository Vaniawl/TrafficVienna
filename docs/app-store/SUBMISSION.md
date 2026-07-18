# TrafficVienna App Store submission pack

This pack is a repository-reviewed source for App Store Connect entry. Localized marketing text lives in `metadata.json`; run `node scripts/validate-app-store-metadata.mjs` before copying it. Do not submit until every release gate below is resolved.

## Verified app record

- Bundle ID: `wellbe.TrafficVienna`
- Version/build: `1.0 (1)`
- Platforms: iPhone and iPad
- Suggested primary category: Navigation
- Suggested secondary category: Travel
- Sign in with Apple and App Group capabilities are present in the project. Enable Sign in with Apple for the production App ID and regenerate distribution profiles before upload.
- The custom `trafficvienna://` scheme is implemented. Do not describe it as a universal link.

## App Review notes

TrafficVienna shows Wiener Linien realtime departures and service alerts. It does not sell tickets or provide A-to-B journey planning.

On first launch, the reviewer can create a device-local email account using any syntactically valid email address and a password accepted by the form; no pre-created account, verification email, or external server is required. The account exists only on the review device. Native Sign in with Apple is an alternative and requires the production capability/provisioning profile.

Location permission is optional. If permission is denied, station search, favourites, alerts, map browsing, and departure boards remain usable; only automatic nearby-stop discovery is unavailable.

To review extension features:

1. Save a station as a favourite, then add the TrafficVienna Home Screen widget.
2. Open a station departure board and start tracking a departure to display its Live Activity.
3. Allow notifications, then create a departure reminder from the same departure context menu.

Realtime results depend on the Wiener Linien endpoint and may be unavailable during provider outages. When cached data is shown, the interface marks it as saved or potentially outdated.

## App privacy answers

Use `docs/PRIVACY.md` as the reviewed source. For the current developer-controlled architecture:

- Tracking: No.
- Developer-operated analytics or advertising: No.
- Email credentials, favourites, routines, recent searches, and session metadata: processed and stored on device, not sent to TrafficVienna servers.
- Precise location: processed on device for nearby-stop lookup, not persisted, and not sent to TrafficVienna servers.
- Apple identity: handled by AuthenticationServices; TrafficVienna has no backend that receives the identity token.
- Required-reason API declarations: packaged in the app and widget privacy manifests.

Do not finalize the App Store privacy label until Wiener Linien confirms whether the `ogd_realtime` service stores source IP addresses and, if so, the purpose and retention period.

## Screenshot shot list

Capture real application UI without device frames, transparency, fabricated data, or claims not available in the build. Use a stable demo state and avoid exposing a real email address or precise location.

| Order | Screen | Marketing message | Required state |
| --- | --- | --- | --- |
| 1 | Smart Home | Vienna departures at a glance | Signed in; populated nearby departures and status card |
| 2 | Search | Find any stop quickly | Search results for a common Vienna station |
| 3 | Departure board | Live departures, clearly grouped | Populated station with multiple lines |
| 4 | Favourites | Your regular lines in one place | At least two saved station/line combinations |
| 5 | Alerts | Important service changes first | Provider response containing a relevant alert, if available |
| 6 | Map | Explore stops around Vienna | Map centered on Vienna; no personal home location |
| 7 | Widget / Live Activity | Updates beyond the app | Composite only if every element is captured from the real build |

Capture the complete set for each localization:

- iPhone 6.9-inch portrait: use an accepted native size such as `1320 × 2868`, `1290 × 2796`, or `1260 × 2736` pixels.
- iPad 13-inch portrait: use `2064 × 2752` or `2048 × 2732` pixels.
- Provide between one and ten screenshots per required device family. Keep the seven-shot story when representative provider data is available; omit a weak or empty provider-dependent frame instead of fabricating content.

## Submission gates

- [ ] Publish `docs/PRIVACY.md` at a stable public HTTPS URL and enter it as Privacy Policy URL.
- [ ] Publish a support page with actual user contact information and enter its HTTPS URL.
- [ ] Confirm `ogd_realtime` IP logging, purpose, and retention; update the privacy label if required.
- [ ] Confirm Wiener Linien data use, attribution, and redistribution rights for App Store distribution.
- [ ] Enable Sign in with Apple for `wellbe.TrafficVienna` and verify a distribution build on a physical device.
- [ ] Replace version/build values in `metadata.json` when the release number changes.
- [ ] Complete age rating, availability, DSA/trader status, export compliance, and content-rights fields in App Store Connect using the account holder's legal facts.
- [ ] Capture localized iPhone and iPad screenshots from the release candidate.

## Apple field limits used by validation

- Name: 2–30 characters.
- Subtitle: at most 30 characters.
- Promotional text: at most 170 characters.
- Description: required, plain text, at most 4,000 characters.
- Keywords: required, each keyword longer than two characters, at most 100 UTF-8 bytes total.
- Screenshots: one to ten JPEG or PNG images without transparency.

Recheck these limits against App Store Connect Help immediately before submission because Apple can update its requirements.
