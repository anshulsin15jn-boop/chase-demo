# Version 0.2 verification

Verified on October 27, 2026. Source commit: `36a913e02fef868477627c7085b25022648ccced`.

## Download and build evidence

- [Prerelease v0.2.0-demo](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/releases/tag/v0.2.0-demo)
- [Download ChaseDemo-unsigned.ipa](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/releases/download/v0.2.0-demo/ChaseDemo-unsigned.ipa)
- [Successful build and tests](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40476706263)
- [Successful publication](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40478578329)

The existing manual workflow ran on standard GitHub-hosted macos-15 with Xcode 26.1.1. No Apple account, certificate, provisioning profile or signing identity was supplied. Version 0.1 remains available separately.

| Verified property | Result |
| --- | --- |
| Display name | Chase Demo |
| Version / build | 0.2.0 / 2 |
| Bundle identifier, unchanged | io.hackathon.fictionalbank.chaselookalike |
| Platform / executable | iPhoneOS, ARM64, Mach-O iOS platform 2 |
| Minimum iOS | 17.0 |
| Archive structure | Payload/BankingHackathonDemo.app, one application |
| Signing | Unsigned; no executable code signature or embedded provisioning profile |
| Icon | AppIcon metadata, compiled PNGs and Assets.car present |
| IPA size | 534,506 bytes |
| SHA-256 | f1ff215a6c6292127563b418c9a8fba97977db910a1dec4973cbcc77e01dbc90 |

The Actions artifact and the actual published release IPA were downloaded independently on Windows. Both passed scripts/verify_ipa.py and have the same SHA-256. The release contains only the IPA, build-verification.json and source-commit.txt.

## Tests

All **36 tests passed** in the successful source build: 21 DemoCore model tests, 8 hosted DemoStore state tests and 7 native UI tests. The native tests ran on an iPhone 16 Pro simulator.

Coverage includes first-name trimming and accented/apostrophe/hyphen names; onboarding persistence and legacy migration; unchanged balances, recipients and historical dates; personalized checking/savings labels; local Today boundaries, explicit dates, time-zone changes and stale drafts; cents entry, zeros, deletion, pasted input, overflow, balance and limit checks; optional recipient fields, nine/ten digits, leading zeros, invalid input, search, persistence and duplicate prevention; message limits, back navigation, cancellation, scheduled payments, confirmation, activity and reset.

Earlier runs exposed a compiler error, visible message clamping and navigation/tap synchronization issues. Targeted fixes were followed by the complete successful run above. The final UI suite includes the previously failing scenarios.

## Visual and icon verification

Ten synthetic screens were captured by the successful workflow at 1206 by 2622 pixels. Amount, amount-error and Add recipient captures from the final build were opened and visually inspected. Onboarding, Accounts and Review captures were also inspected during refinement. The private update references were opened separately and compared visually; none were copied into the repository or CI.

The amount view now has an actual dark $0.00, conditional magenta label/error/underline, a narrow outlined document icon, outlined calendar and revised vertical spacing. The final button fits above the safe area. This was visual inspection, not an automated pixel-difference score. Native status bars, safe areas, fonts and some SF Symbol approximations differ from the reference device.

The authorized 512 by 512 standalone icon was checked for pixel preservation in the cleaned RGB master. All nine catalog PNG dimensions, opacity and approved hashes passed validation locally and in CI. The compiled device application contains AppIcon. The required 1024 image is an upscale of the supplied artwork; no new lettering, composition or rounded mask was added. SpringBoard appearance has not been checked on a real iPhone.

## Privacy checks performed

Reviewed source changes, staged contents before pushes, documentation and release notes. scripts/privacy_check.py passed against the working tree, staged files and reachable Git history, checking approved image hashes, credential patterns and synthetic fixture contacts. The runtime input policy is independent of the reserved-number fixture policy. App and core source searches found no networking or logging calls.

A separate private audit outside Git compared all 11 private reference screenshot fingerprints against reachable source blobs, downloaded workflow outputs, synthetic captures and every entry in the device IPA. It found no exact private reference image copies. The actual release download passed this audit again; its description and three asset names were reviewed. Only the separately authorized icon artwork and derived icon sizes are permitted as committed bitmaps. No OCR extracts or entered device data were used in the build.

These checks combine manual source review, fixture rules and exact image fingerprint checks; they are not a claim of universal automated detection of every possible personal string. Original comparison screenshots remain outside Git.

## Installation limitations

The unsigned device build is ready for local signing with AltStore Classic/AltServer or Sideloadly. Install over the existing app with the same signing account and unchanged app identity; do not uninstall it first. The local storage key is unchanged and automated migration tests preserve recipients and activity. Actual iPhone installation, refresh and preservation through a signing-tool update remain untested. See the [Windows installation instructions](../README.md#windows-and-iphone).
