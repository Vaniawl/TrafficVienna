# TrafficVienna privacy notes

TrafficVienna does not include advertising, analytics, tracking SDKs, or a developer-operated account backend.

## Data handled on device

- Precise location is used transiently to find nearby public transport stops. The coordinates are not sent to TrafficVienna-controlled servers and are not persisted by the app.
- Email credentials created in the app stay on the device. Password verifiers are stored in Keychain; session metadata is stored in UserDefaults.
- Favourites, recent searches, commute routines, theme, and widget state are stored locally in the app or its App Group container.
- Sign in with Apple is handled by Apple's authentication service. TrafficVienna does not operate a server that receives or stores the Apple identity token.
- A user can explicitly export a JSON snapshot containing profile details, appearance/Home/App Lock preferences, favourite stations and routes, commute routines, and recent station identifiers. The export does not include password verifiers, authentication tokens, the Sign in with Apple user identifier, live-data caches, or location history; iOS asks the user where to save or share the resulting file.
- A user can restore a compatible TrafficVienna JSON backup after file-size, schema, value, and count validation plus explicit replacement confirmation. Restore applies appearance, Home layout, favourites, routines, and recents; it ignores exported identity fields and never changes the current account or App Lock. A pre-restore snapshot is reapplied if post-write verification fails.

## Network access

The app contacts Wiener Linien over HTTPS for stop departures and service alerts. Requests contain public stop identifiers, not the device's coordinates, email address, favourites, or authentication credentials. As with any direct HTTPS request, the API operator can observe the source IP address.

## App Store privacy declaration

TrafficVienna does not operate a backend, retain request IP addresses, or track users. Email, precise location, favourites, and search history remain on device. The privacy manifests therefore declare no tracking and no collected data types for code controlled by TrafficVienna.

The public [Wiener Linien privacy material](https://www.wienerlinien.at/datenschutz) describes IP logging for some online services, but the repository does not contain an API-specific agreement or retention statement for `ogd_realtime`. Confirm the realtime endpoint's logging/retention practice with Wiener Linien before finalizing the App Store Connect privacy label; depending on their answer, network-derived device or diagnostic data may require disclosure. Do not infer the final label solely from the manifest. Apple defines collection and on-device processing in its [App Privacy Details guidance](https://developer.apple.com/app-store/app-privacy-details/).

The app declares required-reason API access for app-only UserDefaults (`CA92.1`) and App Group UserDefaults (`1C8F.1`). The widget declares App Group UserDefaults (`1C8F.1`). Re-audit these answers before release whenever analytics, crash reporting, a backend, or another SDK is added.

## Release condition

App Store Connect requires a publicly accessible privacy policy URL. This repository document is the source text, not a published URL; hosting and entering the final URL remain release steps. API-operator IP retention also remains an explicit privacy-label condition.
