Chase Demo 0.4.0 is an independent local banking simulation, not affiliated with Chase or Zelle. No real payments, bank alerts, texts or Siri actions occur.

This update adds full-name onboarding and Personal details settings with an optional middle name. First-name-only profiles complete their last name once without losing accounts, recipients or activity. New profiles receive persisted random starting checking/savings balances and distinct four-digit suffixes. Existing balances are preserved; current accounts gain missing suffixes once while historical sender and account snapshots remain unchanged.

The gray confirmation subtitle is removed without moving the title. A small footer continues to identify the local simulation. Messaging architecture is included only as an immutable, clearly labeled demo payload and disabled provider-neutral interface. It is not wired to payment submission and includes no SMS provider, networking, credentials or sending action.

Download ChaseDemo-unsigned.ipa, an unsigned ARM64 physical-iPhone build for iOS 17 or later. Sign locally with Sideloadly or AltStore Classic/AltServer using the same signing account and app identity, and install over the existing app without uninstalling it. The bundle identifier is unchanged. Apple credentials are never needed in CI.

Publication requires a successful verified build. See docs/VERIFICATION-0.4.md in the repository for actual tests, screenshots and privacy results. Real-device installation and signing-tool update preservation remain untested. Original comparison screenshots and runtime user data are excluded from publication.
