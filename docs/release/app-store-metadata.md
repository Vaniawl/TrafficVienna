# App Store metadata

This packet is the reviewed source for the first Traffic Vienna App Store
submission. Values that depend on App Store Connect account state remain marked
as submission gates rather than assumed complete.

## App information

| Field | Value |
| --- | --- |
| App name | Traffic Vienna |
| Bundle ID | `wellbe.TrafficVienna` |
| Version | `1.0` |
| Build | `1` for the first upload only; increment if App Store Connect already contains build `1` |
| Primary category | Navigation |
| Secondary category | Travel |
| Age rating | Complete the questionnaire for the lowest rating; the app contains no ads, purchases, user-generated content, or restricted material |
| Support URL | <https://github.com/Vaniawl/TrafficVienna/issues> |
| Privacy policy URL | <https://github.com/Vaniawl/TrafficVienna/blob/main/PRIVACY.md> |
| Copyright | `2026 Ivan Dovhosheia` |
| Content rights | Wiener Linien Open Data, attributed in-app under CC BY 4.0 |
| Price | Free |

The privacy URL becomes valid on `main` only after the release-readiness change
is merged. It must return HTTP 200 before submission.

## English (U.S.)

**Subtitle**

Vienna departures, live

**Promotional text**

See nearby departures, service alerts, favourite routes, and Lock Screen updates
in one fast, private Vienna transport companion.

**Description**

Traffic Vienna puts the essentials of Vienna public transport one tap away.

See live departures for nearby stops, search the complete station catalogue,
explore stops on a focused map, and check current service, accessibility, and
stop-change notices before you leave.

Save stations and line directions for quick access. Home Screen and Lock Screen
widgets keep favourite departures visible, while Live Activities can follow a
selected departure on the Lock Screen and Dynamic Island.

Built for speed and clarity:

- live Wiener Linien departures and service information;
- fast station search with recent stops;
- nearby and camera-aware map discovery;
- favourite stations and routes;
- Home Screen and Lock Screen widgets;
- App Shortcuts for Nearby, Search, and Favourites;
- English and German;
- Dynamic Type, VoiceOver, and Reduce Motion support.

Location is optional, used only on-device, and never stored. No account,
advertising, analytics, or tracking is required.

Traffic data is provided by Wiener Linien / Stadt Wien under CC BY 4.0.
Departure information may differ from actual service.

**Keywords**

Vienna,transit,departures,tram,metro,bus,alerts,stations,widget,public transport

**What’s New**

Initial release with live departures, station search, map discovery, service
alerts, favourites, widgets, App Shortcuts, and Live Activities.

## German (Austria)

**Untertitel**

Wiener Abfahrten live

**Werbetext**

Abfahrten in der Nähe, Störungen, Favoriten und Sperrbildschirm-Updates in einer
schnellen, privaten App für die Wiener Öffis.

**Beschreibung**

Traffic Vienna bringt die wichtigsten Informationen zu den Wiener Öffis direkt
auf dein iPhone oder iPad.

Sieh Live-Abfahrten für Haltestellen in deiner Nähe, durchsuche das vollständige
Haltestellenverzeichnis, entdecke Stationen auf einer übersichtlichen Karte und
prüfe aktuelle Betriebs-, Barrierefreiheits- und Haltestellenmeldungen.

Speichere Haltestellen und Linienrichtungen als Favoriten. Widgets für Home- und
Sperrbildschirm zeigen die nächsten Abfahrten, während Live-Aktivitäten eine
ausgewählte Abfahrt auf dem Sperrbildschirm und in der Dynamic Island begleiten.

Für Geschwindigkeit und Klarheit entwickelt:

- Live-Abfahrten und Betriebsinformationen der Wiener Linien;
- schnelle Haltestellensuche mit letzten Suchen;
- Haltestellen in der Nähe und Suche im sichtbaren Kartenbereich;
- bevorzugte Haltestellen und Linien;
- Widgets für Home- und Sperrbildschirm;
- App-Kurzbefehle für Nähe, Suche und Favoriten;
- Deutsch und Englisch;
- Unterstützung für Dynamic Type, VoiceOver und „Bewegung reduzieren“.

Der Standort ist optional, wird nur auf dem Gerät verwendet und nicht
gespeichert. Es sind kein Konto, keine Werbung, keine Analysen und kein Tracking
erforderlich.

Die Verkehrsdaten stammen von Wiener Linien / Stadt Wien und stehen unter
CC BY 4.0. Tatsächliche Abfahrten können von den angezeigten Daten abweichen.

**Schlagwörter**

Wien,Öffi,Abfahrten,U-Bahn,Straßenbahn,Bus,Störungen,Haltestellen,Widget

**Neue Funktionen**

Erste Version mit Live-Abfahrten, Haltestellensuche, Karte, Betriebsmeldungen,
Favoriten, Widgets, App-Kurzbefehlen und Live-Aktivitäten.

## App Review notes

Traffic Vienna has no login, demo account, purchases, ads, or gated content.
Location is optional. If location is declined, Search, Map, Alerts, Favourites,
widgets, and the Vienna-centre fallback remain usable.

Suggested review path:

1. Continue through the three onboarding pages.
2. Decline or allow location; both paths are supported.
3. Search for `Stephansplatz` and open its departure board.
4. Open Alerts to inspect the public Wiener Linien service feed.
5. Favourite a station or line direction, then open Favourites.
6. Add the Traffic Vienna widget to inspect saved departure content.
7. Start a Live Activity from a station departure when Live Activities are
   enabled on the review device.

The app connects only to the public Wiener Linien realtime API at
`https://www.wienerlinien.at/ogd_realtime/`. The bundled station catalogue and
in-app attribution come from Wiener Linien / Stadt Wien Open Data.

## App Privacy answers

These answers intentionally match both bundled `PrivacyInfo.xcprivacy` files and
the public privacy policy:

- Tracking: No.
- Advertising: No.
- Analytics: No.
- Precise location: Not collected; processed only on-device.
- Search history, favourites, and widget preferences: Not collected; stored only
  on-device.
- Contact information and user ID: Not collected; the app has no account.
- Other Data: Collected for App Functionality, linked to the user, not used for
  tracking. This conservative declaration covers station/route request
  identifiers and technical connection data received by the Wiener Linien API.

The final App Store Connect answers must be compared with the processed build’s
privacy report before submission.

## Screenshot order

Equivalent localized 6.9-inch sets are prepared in
`docs/release/screenshots/en-US/` and `docs/release/screenshots/de-AT/`. Every
file is a 1320×2868 JPEG without alpha. The current sets were regenerated from
the premium build and visually inspected on 11 August 2026. Recreate both
localized sets with `bash scripts/capture-app-store-screenshots.sh`:

1. `01-nearby.jpg` — nearby stops and live departures;
2. `02-station-detail.jpg` — full departure board and service context;
3. `03-map.jpg` — Vienna station discovery;
4. `04-alerts.jpg` — active service alerts and filters;
5. `05-favourites.jpg` — saved station and line direction.

These files still need final locale/order confirmation in App Store Connect.

## Export compliance

The app uses HTTPS through Apple’s `URLSession` and no custom or third-party
cryptography. `ITSAppUsesNonExemptEncryption` is `NO`, matching Apple’s
documented exemption for encryption supplied by the operating system.
