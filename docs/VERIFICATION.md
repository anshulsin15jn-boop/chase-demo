# Verified build

[Successful build](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40459700627) and [successful publication](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/runs/40460758871), October 27, 2026.

Source commit: `336dbda4cbb8a6de922b54883b6b25c9afb49973`.

## Test results

Six DemoCore unit tests and three iPhone simulator UI tests passed with zero failures. The build used Xcode 26.1.1 on the standard GitHub hosted macos 15 runner. The UI destination was iPhone 16 Pro.

The checks cover exact cents and invalid input, balance and limit validation, date and message validation, immutable records, duplicate prevention, scheduled balance behavior, name and contact search, serialization and reset. UI tests additionally cover the connected main flow, empty search and formatted phone search, keyboard entry, review and back navigation, both discard choices, confirmation values, saved activity messages, alternate accounts, scheduled dates and frequency, repeated Send taps, restored balance and cleared activity after reset.

## Downloaded release verification

The published release IPA was downloaded again and independently passed the same verifier locally. Its hash matches the successful build artifact and the release asset digest.

| Property | Verified value |
| --- | --- |
| Archive | Payload/BankingHackathonDemo.app |
| Display name | Hackathon Demo |
| Bundle identifier | io.hackathon.fictionalbank.chaselookalike |
| Platform | iPhoneOS |
| Architecture | arm64 |
| Mach O build platform | physical iOS, value 2 |
| Minimum iOS | 17.0 |
| Device family | iPhone, value 1 |
| Signing | No code signature directory or provisioning profile |
| Archive file entries | 6 |
| SHA256 | ee27fac33d39ab08089aaa98fec5e117da6bf55ed702e453c070a25589f527e7 |

## Visual review

All eight private references were opened and mapped to seven screens before implementation. References 6 and 8 depict the same Confirmation view. Seven running app screenshots were visually compared at the iPhone 16 Pro portrait proportions, and header spacing, card height, recipient alignment, text colors, separators and status appearance were refined. The native keyboard was confirmed visible in the search capture.

Product illustrations and specialized banking icons use SF Symbols. The purple badge is a simple glyph, and Siri uses a waveform symbol. Invented names and contacts wrap differently in some places. Native safe areas, the Dynamic Island, status indicators, keyboard details and font rendering vary with iOS and device. The entrance animation and Reduce Motion path are implemented; no separate animation frame or accessibility setting test is claimed.

## Privacy checks performed

The eight originals remain outside the repository. Tracked files and reachable Git history were checked for reference files, credential patterns and non-demo app contacts. Fixtures and generated app captures were manually reviewed for fictional data. A private local fingerprint audit compared all original image bytes against reachable source blobs, downloaded diagnostics, screenshots, and IPA archive entries; no exact original image copies were found. The IPA metadata and long synthetic account and example.com fixture strings were verified. No original images, OCR output, or private reference details are in the release files or release notes.

These checks are scoped to the implemented fixtures, reviewed files and collected build outputs. They are not an automated detector for every possible personal name. The app contains no network transfer code, banking login, camera capture, Siri integration, signing identities or Apple credentials.

## Device testing still required

The unsigned IPA requires AltStore Classic to sign and install it. Installation, trust prompts, refresh behavior and update data preservation must still be tested on the user's iPhone. No successful physical installation is claimed.
