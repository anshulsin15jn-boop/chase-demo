Chase Demo 0.3.0 is an independent hackathon simulation, not affiliated with Chase or Zelle. No real money, registration checks, emails, texts or Siri actions occur.

Created and existing local recipients now share a complete simulated identity: registration badge, Personal account and active-since metadata. A reusable vector badge appears throughout the app. Confirmation uses the submitted payment snapshot for its uppercase full name, selected date, exact amount and reference-style notification copy. The Siri demonstration has dynamic wording and a drawn multicolor orb.

Legacy automatic registration defaults migrate without changing IDs, names, contacts, activity, balances or payment dates. Explicit new-schema metadata is preserved. The bundle identifier and local storage key remain unchanged.

Download ChaseDemo-unsigned.ipa, an unsigned ARM64 physical-iPhone build for iOS 17 or later. Sign locally using AltStore Classic/AltServer or Sideloadly, with the same signing account and app identity as before. Install over the existing app without uninstalling it to retain local data. Apple credentials are never needed in the app or CI.

The publication job requires a successful verified build. See docs/VERIFICATION-0.3.md in the repository for actual test and visual review results. Real-device installation and update data preservation remain untested. Comparison screenshots are excluded; only the previously approved AppIcon bitmap assets are included.
