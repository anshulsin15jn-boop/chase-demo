# Disabled messaging boundary

This version includes architecture only. Payment submission remains a local ledger operation. It does not call a message transport. There is no SMS button, provider SDK, network endpoint, phone discovery, provider credential or live delivery implementation.

DemoMessage is immutable content derived from a submitted Payment snapshot: payment ID, uppercase complete sender name and integer cents. Its text explicitly identifies CHASE DEMO, LOCAL SIMULATION and that no real money was transferred. It does not impersonate a bank alert. Editing a draft or profile cannot change content derived from an existing snapshot.

DemoMessageDelivery is the future provider-neutral asynchronous interface. DisabledDemoMessageDelivery always fails with a typed disabled error, and is not wired into the app. Tests verify the content boundary and disabled behavior. Do not remove the simulation identification from delivery copy.

Any later approved live integration belongs behind a separate server-side adapter. Provider secrets must remain on that server, outside the iPhone app, public repository, CI logs and IPA. A future implementation needs explicit recipient opt-in, a designated test-recipient allowlist, authenticated authorization, payment-ID idempotency, revocation and provider failure handling before delivery is enabled. No such backend or credentials are configured by this update.
