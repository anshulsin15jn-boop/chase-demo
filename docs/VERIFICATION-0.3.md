# Version 0.3 verification

Verified October 27, 2026. Built source commit: `5788740fb5e6563a28adfd8dca138424ca488c87`.

## Downloads and CI evidence

- [Prerelease v0.3.0-demo](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/releases/tag/v0.3.0-demo)
- [Direct unsigned IPA download](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/releases/download/v0.3.0-demo/ChaseDemo-unsigned.ipa)
- [Successful final build and tests](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40556264539)
- [Successful publication](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40559505827)
- [Initial implementation and capture run](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40542013669), also successful

Both source runs used the existing standard macos-15 workflow with Xcode 26.1.1. The second run followed a measured visual refinement to the badge proportions and Siri orb shading. No Apple signing credentials or paid capabilities were supplied. Earlier prereleases remain unchanged.

| Verified property | Final result |
| --- | --- |
| Display name | Chase Demo |
| Version / build | 0.3.0 / 3 |
| Bundle identifier, unchanged | io.hackathon.fictionalbank.chaselookalike |
| Platform / architecture | iPhoneOS / ARM64, Mach-O iOS platform 2 |
| Minimum iOS | 17.0 |
| Structure | One app at Payload/BankingHackathonDemo.app |
| Signing | Unsigned; no executable signature or embedded profile |
| App icon | AppIcon metadata, compiled PNGs and Assets.car verified |
| IPA size | 561,052 bytes |
| SHA-256 | a871517a4dcb51600c5963e7f5ab88f20f79f72d177236b14f7f4dc443eeb816 |

The Actions IPA and the actual public release download were independently verified on Windows with scripts/verify_ipa.py. Their SHA-256 values and source-commit.txt contents match. The release contains only the IPA, build-verification.json and source-commit.txt.

## Automated verification

All **41 tests passed** in both source runs: 26 model tests, 8 hosted state tests and 7 native UI tests. The final UI run used an iPhone 16 Pro simulator.

New model checks cover complete metadata defaults; migration of legacy automatic false registration values without losing recipient IDs, names, numbers, profile, balances or activity; explicit metadata round trips; full uppercase accented, apostrophe and hyphenated names; missing optional fields; exact confirmation and Siri interpolation; formatted selected dates and exact amounts; and submitted snapshot consistency after draft changes.

The expanded UI flow actually creates name-only, nine-digit number-only, ten-digit number-only and combined recipients. The combined case uses a long multiword, hyphenated name. It checks the registration/account/active-since lines, badge accessibility label and amount-field clearance, completes payments, verifies full uppercase confirmation text and exact amounts, checks omitted unavailable fields and Siri wording, and opens/closes the local Siri demonstration sheet. Existing onboarding migration, persistence, search, currency entry, cancellation, future dates, account selection, duplicate submission, activity and reset tests also ran.

## Visual review

The successful final workflow captured 14 synthetic screens at 1206 by 2622 pixels. The final created-recipient Enter Amount, created-recipient Confirmation, long-name Confirmation, number-only Confirmation, Review and directory captures were opened and visually inspected. The private Enter Amount and Confirmation targets were opened separately for comparison. No reference pixels were used in the app.

The initial capture showed an oversized badge. The final avatar badge was reduced to 32 percent of avatar size, retaining its lower-right overlap and small white backing. The same custom SwiftUI z shape is used in recent recipients, directory rows, Enter Amount, Review and Confirmation. The Siri orb gained subtle edge shading after the first comparison. This review was visual, not an automated pixel-difference score.

Created recipients now have the full identity block and enough intrinsic height above the amount section. Confirmation uses the requested paragraph structure with the full uppercase supplied name, the submitted date formatted as a calendar date, and the submitted amount. The name/registration/contact text uses the same shared helper as payment identity components. No missing name or phone is invented. Long names wrap; content scrolls independently above the pinned Done button. UI tests scroll through the long-name and missing-field cases.

The Siri orb is a hand-drawn vector approximation, not the exact proprietary bitmap. Native font rendering, safe areas and line wrapping differ slightly from the reference device. Required full names and formatted dates can also add lines compared with the reference's shorter text. No smaller-device or real-iPhone screenshot comparison is claimed.

## Privacy and local data

Reviewed source diffs, staged contents, documentation, release description and asset names. scripts/privacy_check.py passed against tracked working files, the index and reachable history, checking approved icon image hashes, fixture contact patterns and credential patterns. App/core source searches found no networking or logging calls. The existing icon catalog validator passed locally and in both builds; no new bitmap assets were added.

A separate audit outside the repository compared all 15 private comparison-image fingerprints against reachable source blobs, downloaded workflow outputs, synthetic captures and every IPA archive entry. It found no exact reference image copies. The actual public release download passed the audit again. Only the previously authorized standalone AppIcon and its derived sizes are permitted as tracked bitmaps. No OCR text or local device user data was used in CI or publication.

These checks combine manual source review, fixture rules and exact image fingerprint checks; they do not claim universal automated detection of every possible personal string. All comparison originals remain outside Git.

Decoding recipients without the new metadata object upgrades the old automatic registration default. Explicit new-schema metadata takes precedence, including an explicit false registration value. The existing local storage key remains `fictional-demo-state-v1`; IDs, names, raw numbers and payment values are not replaced. Runtime input stays on the device. The notification paragraph and Siri command are demonstration copy; no external registration, messages, transfers or Siri actions occur.

## Installation limitation

The IPA still requires local signing through Sideloadly or AltStore Classic/AltServer. Install over the existing app with the same signing account and app identity; do not uninstall it first. Actual iPhone installation, signing refresh and preservation through a real signing-tool update remain untested. See the [Windows instructions](../README.md#windows-and-iphone).
