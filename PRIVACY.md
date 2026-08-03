# Traffic Vienna Privacy Policy

Last updated: 30 July 2026

Traffic Vienna is an independent public-transport companion for Vienna. It does
not require an account and does not use advertising, analytics, or tracking.

## Data stored on your device

The app stores favourites, recent station searches, onboarding state, widget
preferences, and departure reminders locally. Favourites and widget content use
an Apple App Group so the app and its widget can share that information on the
same device.

If an earlier development build stored an optional Apple profile, the current
version removes that legacy Keychain entry on launch. The released app does not
offer or require an account.

## Location

Location access is optional. When granted, the app uses the current location on
the device to find nearby stops. The location is not persisted, logged, or sent
to Traffic Vienna or to the transport data provider.

## Live departures and alerts

Traffic Vienna requests live departures and service information directly from
the Wiener Linien Open Data API over HTTPS. Those requests contain the selected
station or route identifier. As with any network service, Wiener Linien receives
technical connection information such as an IP address and may process it under
its own privacy terms. Traffic Vienna does not operate a backend and does not
receive the provider's server logs.

Wiener Linien describes its open-data service at
<https://www.wienerlinien.at/web/guest/open-data> and its privacy information at
<https://www.wienerlinien.at/datenschutz>.

## Notifications

If you choose **Remind me** for a departure, Traffic Vienna asks iOS to schedule
a local notification on that device. The route, stop, destination, and reminder
time are held by iOS for delivery. They are not sent to Traffic Vienna or to a
remote push-notification server. Notification permission is requested only after
you choose to create a reminder.

## Your choices

You can remove favourites, recent searches, and pending departure reminders in
the app. You can deny or revoke location and notification access in iOS Settings.
Deleting the app removes its local app and widget data.

## Contact

For support or privacy questions, open an issue at
<https://github.com/Vaniawl/TrafficVienna/issues>.
