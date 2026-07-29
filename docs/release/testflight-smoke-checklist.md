# TestFlight release smoke checklist

Run this checklist on the exact processed build selected for release. Record the
device model, OS version, build number, tester, date, and result for every item.

## Install and launch

- Install from internal TestFlight, not Xcode.
- Confirm a clean first launch shows exactly three onboarding pages.
- Allow location and confirm nearby Vienna stops plus live departures.
- Reinstall or revoke location, choose Don’t Allow, and confirm Search, Map,
  Alerts, Favourites, and the Vienna-centre fallback remain usable.

## Core journeys

- Search for `Stephansplatz`, open the station, and refresh departures.
- Open a service alert and return without losing station state.
- Save one station and one route direction; confirm both appear in Favourites.
- Force-quit and relaunch; confirm favourites persist and no account prompt exists.
- Disconnect the network after loading data; confirm saved/stale labels appear
  rather than presenting old data as live.

## System surfaces

- Add small, medium, and large Home Screen widgets.
- Add at least one supported Lock Screen widget.
- Confirm a saved route appears, countdowns advance, and manual refresh works.
- Tap the widget from a terminated app and confirm Favourites opens.
- Start a Live Activity from a departure; confirm Lock Screen and Dynamic Island
  presentation, then end it.
- Run Nearby, Search, and Favourites App Shortcuts from Shortcuts or Spotlight.

## Accessibility and platform

- Check the main journeys with VoiceOver.
- Check maximum Accessibility Dynamic Type for clipping and unreachable actions.
- Enable Reduce Motion and confirm repeating shimmer/pulse and spatial transitions
  become static or opacity-only.
- Repeat the basic smoke on one supported iPad.

## Processing and policy

- Inspect App Store Connect processing warnings and the generated privacy report.
- Confirm app and widget bundle IDs, version/build, entitlements, encryption
  answer, privacy answers, age rating, content rights, screenshots, and review
  notes match `docs/release/app-store-metadata.md`.
- Confirm support and privacy URLs return HTTP 200 from a signed-out browser.

## Result

Any crash, blank widget, wrong deep link, misleading freshness state, missing
privacy URL, signing mismatch, processing warning, or inaccessible required action
is a release blocker. Fix it in a new build number and rerun the complete checklist.
