# Account authentication provider evaluation

Status: recommendation only. No provider SDK, project, credential, domain, or
remote account has been added to TrafficVienna.

## Product boundary

Traffic information remains available without an account. An account is optional
and exists only to provide a durable identity for future cross-device preferences.
The email path must be real authentication; storing an email locally is not an
acceptable substitute.

The required lifecycle is:

- native Sign in with Apple and passwordless email entry;
- one user identity when a person links Apple and email intentionally;
- restore, sign-out, provider revocation, reauthentication, and account deletion;
- no provider secret, service-role key, identity token, or authorization code in
  source control, logs, `UserDefaults`, or the existing favourites payload;
- anonymous transport use before, during, and after an account flow.

## Recommendation: Firebase Authentication

Use Firebase Authentication with native Sign in with Apple and passwordless email
links, subject to explicit approval before any external project or Apple Developer
configuration is changed.

Firebase is the smaller fit for this acceptance boundary because its Apple-platform
SDK documents all three required operations directly:

- [email-link authentication](https://firebase.google.com/docs/auth/ios/email-link-auth)
  with verified ownership and Firebase Hosting universal links;
- [provider linking](https://firebase.google.com/docs/auth/ios/account-linking) so
  Apple and email can resolve to one Firebase user after explicit user action;
- [current-user deletion](https://firebase.google.com/docs/auth/ios/manage-users)
  from the authenticated client, with recent sign-in required for the sensitive
  operation.

The [Firebase Apple guide](https://firebase.google.com/docs/auth/ios/apple) uses
the native `AuthenticationServices` result and a cryptographically secure nonce.
It also calls out Apple's explicit-consent requirement before an Apple identity is
linked to identifying account data and the private-email-relay configuration needed
when Firebase sends email to an Apple relay address.

## Why Supabase is not the default for this slice

Supabase remains a credible alternative if remote favourites, Postgres, and
row-level security become the primary next feature. It supports passwordless auth
and native Apple entry. However, its documented Swift user deletion operation is
an [Auth Admin method](https://supabase.com/docs/reference/swift/auth-admin-deleteuser),
and [Auth Admin requires a secret key on a trusted server](https://supabase.com/docs/reference/swift/admin-api).
TrafficVienna would therefore need an additional trusted server or Edge Function
for safe self-service deletion. A service-role or secret key must never be embedded
in the app.

## Required configuration after approval

1. Create a dedicated Firebase project and register
   `wellbe.TrafficVienna`; add only `FirebaseAuth` through Swift Package Manager.
2. Keep `GoogleService-Info.plist` environment-specific and review its contents;
   never add Apple private keys or other server credentials to the repository.
3. Enable Email/Password plus passwordless Email Link, choose the Firebase Hosting
   link domain, and add its `applinks:` entry to Associated Domains.
4. Enable Sign in with Apple for the App ID, regenerate the provisioning profile,
   then configure Firebase's Apple provider and Apple private-email relay.
5. Replace the device-only Apple profile as the session source of truth with a
   narrow `AccountAuthenticating` boundary backed by the Firebase auth-state
   listener. Preserve anonymous mode and migrate no local favourites implicitly.
6. Implement a secure random nonce for Apple, universal-link completion for email,
   explicit provider-link consent, reauthentication, remote delete, token
   revocation where required, cancellation, and user-safe error states.
7. Test every lifecycle path with provider adapters or the Firebase Auth Emulator;
   complete physical-device Apple and email-link acceptance before calling the
   account slice complete.

## Approval gate

Provider adoption changes the dependency graph and requires external Firebase,
Apple Developer, Hosting-domain, and private-relay configuration. Those mutations
remain paused until the user explicitly approves Firebase Authentication (or chooses
another provider). The current native Apple/device-only session stays intact until
the real replacement is configured and tested.
