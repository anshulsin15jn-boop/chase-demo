# Version 0.4.1 verification

Version 0.4.1/build 5 is the non-SMS release. It removes the unused messaging architecture while retaining full-name onboarding, editable profile details, persisted randomized starting balances and distinct account suffixes. Local payment data and the bundle identifier remain unchanged.

Build source: `0096332ab69bde78a06b9d9dd710158fb942ae86`.

[GitHub Actions run](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40629744814) succeeded on the standard macos-15 runner with Xcode 26.1.1.

- 33 model tests, 9 state tests and 8 simulator UI tests passed (50 total, zero failures).
- Release device compilation and IPA packaging passed. The downloaded IPA was independently rechecked on Windows: physical iOS ARM64, unsigned, iOS 17+, Chase Demo display name, AppIcon present, version 0.4.1/build 5, and unchanged `io.hackathon.fictionalbank.chaselookalike` bundle identifier.
- Source search found no messaging transport, networking or endpoint settings in App/Sources/Tests. Binary and archive checks found no configured SMS implementation markers or endpoint files.
- Source, staged files and reachable history passed the existing privacy audit. The IPA archive contains only the application executable, metadata and compiled app assets; no reference screenshots or credentials were added. Release files are limited to the unsigned IPA and sanitized verification/source metadata.
- Synthetic simulator screenshots of onboarding, Personal details, Enter Amount and Confirmation were visually inspected. They retain the name fields, recipient metadata/badge, zero amount entry and local-simulation notice. No new comparison against private reference screenshots was performed in this packaging update.

IPA SHA-256: `eefef146664880f0ed8b224a2abe3b51f2ea53aa15536062a9e883d295a805ff`.

Actual iPhone installation remains untested. Install with Sideloadly or AltStore using the same signing account and app identity; do not uninstall the existing app if you want to retain its local data. No SMS service is included or required. Existing vector-icon and native-iOS layout approximations remain unchanged.
