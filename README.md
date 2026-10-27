# Banking Hackathon Demo

A native SwiftUI banking simulation for iPhone, inspired by the private visual references. The display name is **Hackathon Demo**. The launch screen explains the project. This project is independent and is not affiliated with Chase or Zelle.

All accounts, contacts, messages, balances, and registration details are fictional. Every payment is a local simulation. The app has no networking, login, camera, Siri integration, or paid Apple capabilities.

## Download and install

Open [Releases](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/releases) and select the newest hackathon prerelease. Download `BankingHackathonDemo-unsigned.ipa`. You need an iPhone with iOS 17 or later and AltStore Classic. This unsigned device IPA needs AltStore to sign it before installation.

If using an [Actions build](https://github.com/anshulsin15jn-boop/chase-hackathon-demo/actions/workflows/ios.yml), open a successful run and download `BankingHackathonDemo-unsigned` under Artifacts. Extract the ZIP on Windows and use the `.ipa` inside. Do not rename the artifact ZIP to `.ipa`.

### On Windows

Follow the [official Windows installation guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows). It currently specifies Apple supplied iTunes and iCloud, with a documented alternative for Microsoft Store iCloud. Download AltServer from that guide, extract its installer, install it, and run AltServer as administrator. Allow private network access when requested.

Connect and unlock the iPhone, accept computer trust, and enable WiFi sync in iTunes. Use the AltServer taskbar icon, select **Install AltStore**, and choose the connected phone. Complete Apple sign in through your local installation. Never enter Apple credentials in this app, source code, GitHub, or Actions.

### On iPhone

Trust the developer identity under Settings > General > VPN & Device Management, or the equivalent profile management entry for your iOS version. Enable Developer Mode under Settings > Privacy & Security, then follow the device restart prompts. See the [official guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) for version differences.

Download the release directly in Safari to Files, or transfer the Windows download using a file transfer method you already use. Keep the `.ipa` extension. With AltServer running and reachable, open AltStore Classic, select **My Apps**, tap **+**, and choose the IPA in Files. Complete any local AltStore prompts and wait for signing and installation. If your version exposes a Files share action for AltStore, that is another import route.

Open **Hackathon Demo**, read the demo disclosure, and select **Enter demo**.

### Refresh and updates

The official [Getting Started guide](https://faq.altstore.io/altstore-classic/your-altstore) documents seven day expiration for regular accounts, three active sideloaded apps, and **Refresh All** in My Apps. AltStore itself uses an app slot. Refresh before expiry. Keep AltServer available on the same network or connect by USB, as described in the [AltServer guide](https://faq.altstore.io/altstore-classic/altserver). Paid developer accounts have different signing limits and typically longer validity; use the expiry shown by your local AltStore rather than assuming the regular account window.

For an update, import the new IPA using the same Apple account and app identity. Do not uninstall the old app first if you want to preserve local demo activity. The bundle identifier stays `io.hackathon.fictionalbank.chaselookalike`. AltStore performs the signing and may map this to your account. Installation and preservation of data still require testing on your iPhone.

## Use the demo

Accounts > Send | Zelle, or Pay & transfer > Send money, opens recipients. Search, select a recipient, enter an amount and optional message, choose account and date, then review and submit. Done returns to Pay & transfer. Activity shows the immutable payment record. More > Reset demo restores fixtures and clears activity.

The injected demo clock defaults to November 12, 2026 in UTC. Future dates create scheduled records and do not reduce balances. Repeating payments record the frequency only; there is no background transfer engine. Drafts survive back navigation in the current session. Activity and added fictional recipients persist locally between launches. Reset removes that saved demo state.

New contacts are restricted to reserved 202 555 0100 through 0199 numbers or example.com email addresses. Only enter invented names.

## Build responsibilities

| Location | Work |
| --- | --- |
| Windows | Edit source, trigger workflows, download the IPA, run AltServer |
| GitHub standard macOS runner | Run Swift tests, generate the Xcode project, run simulator UI tests, build the unsigned iPhone app |
| iPhone | AltStore signing and installation, device trust, Developer Mode, demo use and installation testing |

The manual **Build and verify iPhone demo** workflow uses the standard `macos-15` runner and an installed Xcode. It generates the project with XcodeGen, compiles a Release `iphoneos` app with signing disabled, packages `Payload/BankingHackathonDemo.app`, then verifies ARM64 and Mach-O physical iOS platform metadata. Build artifacts expire after three days. No pushes automatically start duplicate builds.

The separate **Publish verified hackathon prerelease** workflow accepts a successful build run ID and a new tag. Only that job has release write permission. It checks the run result, source commit, IPA hash, and device metadata before publication. No signing secrets are used.

On a Mac with Xcode and XcodeGen, run `swift test`, `xcodegen generate`, and open the generated project. Generated Xcode projects and build outputs stay out of Git.

## Verification and visual notes

Focused model tests cover exact cents, invalid amounts, balance and limit checks, date validation, scheduled balances, immutable snapshots, duplicate IDs, message limits, search, serialization, and reset. UI tests cover the connected flow, keyboard search, validation alerts, back navigation, cancellation, confirmation, activity, and reset. Build success is reported only after CI runs.

The simulator capture script produces seven screenshots using fictional fixtures. The simulator is selected for proportions close to the references, preferring iPhone 16 Pro or 17 Pro. Native status bars and keyboards vary by iOS version. Product illustrations, banking icons, the purple registration badge, and the Siri symbol use SF Symbols or simple text approximations. The transition screenshot is implemented as an entrance animation with Reduce Motion support.

Original reference images are outside the repository. They are never app resources, workflow inputs, artifacts, or release attachments. The privacy checker inspects tracked files and reachable source history, rejects reference image files and credential patterns, and checks app contacts against synthetic formats. Its checks supplement manual review; they do not claim to detect every possible personal name.

Real iPhone installation testing is still required even when compilation, simulator tests, and IPA verification pass.
