# Chase Demo

An independent native SwiftUI hackathon simulation, not affiliated with Chase or Zelle. No real transfers, notifications, contact discovery, analytics, or banking sign in. Names and recipients entered at runtime stay in the app's local device storage.

## Version 0.3 update

Version 0.3 adds a shared demo recipient identity and a revised Confirmation screen. Created and legacy recipients default to simulated registration, Personal account and Feb 2025 activity metadata. These are presentation fixtures, not registration checks. A native vector badge is shared by every avatar, and the Siri demonstration button uses a drawn multicolor orb.

Confirmation uses the immutable submitted payment's full uppercase recipient name, selected calendar date and exact amount. Its reference-style notification paragraph is demonstration interface copy only; no messages or money are sent. The entry row continues to show Today when appropriate. See [version 0.3 verification](docs/VERIFICATION-0.3.md) for the update's build and release status.

The app asks for a first name once, including after an update from version 0.1. Surrounding whitespace is removed; empty names are rejected. Accents, apostrophes and hyphens are supported. The existing local storage key and bundle identifier are retained, so adding the first name preserves saved recipients, balances and activity.

For a synthetic name of Avery, account labels are `AVERY CHECKING (..5020)` and `AVERY SAVINGS (..5020)`. Checking and savings remain separate accounts. The local first name is also the simulated sender identity.

New payments start at **Today**, using the device's actual local calendar and time zone. The Today shortcut is a rolling default; choosing a day in the calendar is an explicit selection. Explicit calendar days survive navigation, clock refreshes and time-zone changes. Foreground and significant time changes refresh the current day. Review and Send recheck the date, and an explicit date that has become past must be corrected. Existing payment timestamps are never rewritten, and legacy UTC records retain their original displayed calendar day.

Every new payment starts at a real, dark `$0.00`. Number pad digits insert cents automatically: `5` is `$0.05`, `500` is `$5.00`. Backspace removes one entered digit. Leading zeros are preserved internally, and deleting all digits restores `$0.00`. Plain pasted ASCII digits are accepted. An edit containing punctuation, spaces, non-ASCII numerals or letters is rejected as a whole and leaves the value unchanged. The app guards integer overflow and validates the fictional balance and $10,000.00 sending limit before submission. Zero amount errors appear inline only after Review is pressed.

## Recipients

Name only, number only, or a combination are supported. Email remains an optional separate field. At least one valid value is required. Any 9 or 10 ASCII digits are accepted for this local simulation. Phone input uses a number pad and is stored as an unformatted string, preserving leading zeros. Nine digits display as three groups of three; ten digits use the standard parenthesized area code format. No missing digit is invented.

Names without contacts do not show blank contact lines. Number-only recipients use the formatted number as their label and a generic avatar, without an invented Registered as name. Every new recipient receives the same simulated registration metadata as the samples. Repeated saves are guarded, duplicates are checked locally, and recipients persist between launches.

Version 0.1/0.2 stored an automatic false registration value for created recipients. Decoding recipients without the new metadata object replaces that legacy presentation default, including recipients embedded in activity snapshots. IDs, names, raw numbers, account balances, payment IDs, dates and amounts are retained. Explicit metadata stored in the new schema takes precedence, including an explicit unregistered state. The local storage key remains unchanged.

Bundled samples and automated tests use synthetic data. Reserved numbers and example.com addresses are a fixture privacy policy, not a restriction on local runtime entry. Do not include real user data in shared screenshots or reports.

## Download and install an update

Download [ChaseDemo-unsigned.ipa, version 0.3.0](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/releases/download/v0.3.0-demo/ChaseDemo-unsigned.ipa), or open the [prerelease](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/releases/tag/v0.3.0-demo). All 41 tests passed and the published device IPA was independently verified after download. See [version 0.3 verification](docs/VERIFICATION-0.3.md) for results, screenshot review, privacy checks and remaining installation limitations. Earlier releases remain available separately.

For an Actions download, open a successful [build run](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/workflows/ios.yml), download the `ChaseDemo-unsigned` artifact and extract its ZIP. Use the IPA inside; do not rename the outer artifact ZIP to IPA.

The app supports iOS 17 or later. The IPA is unsigned and needs local signing through AltStore Classic/AltServer or Sideloadly. Apple credentials never belong in this app, its source, GitHub issues or Actions secrets.

### Windows and iPhone

Follow the current [official AltStore Windows instructions](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) or [official Sideloadly instructions](https://sideloadly.io/). AltStore's Windows guide specifies Apple supplied iTunes and iCloud, with a documented alternative for Microsoft Store iCloud. Install AltServer locally, connect and trust the unlocked phone, enable WiFi sync where required, and install AltStore from AltServer's device menu. Complete Apple sign in only through the local installer.

For AltStore, place the IPA in iPhone Files, either by downloading the release in Safari or transferring the Windows download. With AltServer reachable, open AltStore Classic, use **My Apps > +**, and select the IPA. Trust the developer identity in iOS Settings under the applicable device management entry and enable Developer Mode when prompted. Labels vary with iOS; follow the linked official guide.

For Sideloadly, import the IPA into the local Windows app, select the connected iPhone and the same signing account used for the existing installation, and start signing and installation. Keep the original app identity.

**To preserve existing data, install over the existing app without uninstalling it. Use the same Apple/signing account and keep bundle identifier `io.hackathon.fictionalbank.chaselookalike`.** The visible name and icon change to Chase Demo. The first name is requested once, and the migration retains recipients and activity. Data preservation and installation must still be tested on the actual iPhone.

Regular accounts normally require refreshing before the seven day expiry and have three active app slots, including AltStore itself. See [AltStore Getting Started](https://faq.altstore.io/altstore-classic/your-altstore), [AltServer connectivity](https://faq.altstore.io/altstore-classic/altserver), and [App ID limits](https://faq.altstore.io/altstore-classic/app-ids). Paid account validity differs; use the expiry shown by the local signing tool. This app has no extensions or paid Apple capabilities.

## Build and checks

Windows is used for editing, downloading and local signing tools. GitHub's standard `macos-15` runner compiles with installed Xcode. The iPhone performs installation, trust and Developer Mode steps and runs the demo.

The existing manual [build workflow](.github/workflows/ios.yml) runs source privacy checks, DemoCore tests, hosted state tests and native UI tests. It validates the supplied icon catalog, generates the Xcode project, captures synthetic screens and builds a Release physical-device app with signing disabled. The verifier checks iPhoneOS metadata, ARM64 Mach-O platform 2, no executable code signature, correct icon metadata and IPA structure. Artifacts expire after three days. The separate [publication job](.github/workflows/publish.yml) alone has release write permission and verifies the successful source run and file hash before creating a new prerelease.

The display name is **Chase Demo**, version **0.3.0**, build **3**. Internal Xcode target and archive folder names remain BankingHackathonDemo. The distinct bundle identifier is unchanged. No Apple signing credentials are used in CI.

On a Mac, run `swift test`, `python3 scripts/generate_icon.py`, `xcodegen generate`, and open the generated project. The historical icon script name is retained, but it only validates the committed supplied artwork and nine opaque icon sizes. It does not generate replacement artwork.

Production uses `Date()` and the local calendar. Deterministic clocks, synthetic onboarding and legacy migration seeds are confined to test injection and a debug-only CI harness; normal app launches do not use the fixed test date.

## Privacy and visual notes

The three update comparison screenshots and all original references remain outside Git. Only the supplied standalone icon is authorized as an app asset. A hash allowlist permits its reviewed PNG sizes; other bitmap files, renamed images, credential patterns and personal fixture contacts are rejected by the source/history check. This policy does not inspect or prohibit legitimate local runtime input.

The 512 by 512 supplied artwork was preserved pixel for pixel in the cleaned source and resized to the required opaque AppIcon sizes, including 1024. No lettering or rounded mask was added. iOS applies its own mask. The 1024 version is an upscale and contains no invented additional detail.

The recipient document and calendar icons are native vector shapes. The amount error color and underline are conditional validation styling. Other specialized banking illustrations remain documented SF Symbol approximations; native safe areas, keyboards and status indicators vary with iOS.

More > Reset demo restores sample balances and recipients and clears simulated activity, while retaining the first name so onboarding is not repeated.
