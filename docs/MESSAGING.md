# Optional demo SMS

SMS is off until explicitly configured in More > Demo SMS. This source update has not been compiled into an IPA. The existing installed app is unchanged.

The message template is:

> CHASE DEMO - LOCAL SIMULATION: {FULL_SENDER_NAME} recorded a simulated payment of {AMOUNT} to {RECIPIENT}. No real money was transferred. Independent demo, not a bank payment alert.

The sender, recipient and amount come from the immutable submitted payment. The relay generates this exact template itself and rejects altered client copy. Names and amounts are transmitted to the relay and SMS provider only when this optional feature is enabled. No banking service, enrollment link, contact discovery or real transfer is involved.

## Private configuration

1. Copy `scripts/demo_sms.env.example` to the gitignored `scripts/demo_sms.env`. Enter provider account SID, auth token and sending number locally. Never put provider credentials in the app, GitHub or chat.
2. Set `DEMO_SMS_ALLOWED_TO` to comma-separated E.164 numbers belonging to designated test recipients who explicitly agreed to receive demo texts. Only ten-digit US numbers are supported for SMS; nine-digit and name-only recipients still work for local payments.
3. Generate a random relay token locally (Python `secrets.token_urlsafe(32)`) and put it in `DEMO_SMS_RELAY_TOKEN`. This is separate from provider credentials.
4. Run `py -3 scripts/demo_sms_server.py` on Windows. Missing configuration prevents startup. The helper binds only to `127.0.0.1:8787`. Expose it through your configured HTTPS reverse proxy for iPhone access; this change does not deploy one.
5. In a future app build containing these changes, open More > Demo SMS. Enter the HTTPS URL ending in `/send` and the relay token, acknowledge recipient opt-in, and choose Enable demo SMS. This saves the token to device-only Keychain storage and enables future payment requests without restarting. It does not send a test message. The old bundled `MessagingEndpoint.url` is no longer used.
6. Turn off SMS in the same screen to disable future requests and delete the stored token. Remove a destination from the server allowlist and restart the relay to revoke its permission. Requests already sent cannot be recalled.

Provider acceptance is not proof of delivery. Provider/account restrictions may also block delivery. The app keeps the local payment even if SMS fails; it currently does not surface delivery status or provide retries.

## Request protection and storage

The relay requires bearer authentication, designated-recipient allowlisting and structured snapshot fields. It validates integer amounts and generates the approved text. Its ignored SQLite journal persists only payment IDs, content hashes and status codes, never names, phone numbers or message bodies. Repeated payment IDs cannot initiate a second provider call, including after restart or an uncertain provider failure. Do not delete the journal to retry uncertain sends.

The helper suppresses request logging and never prints provider responses or credentials. Your reverse proxy and provider have their own logging/retention settings. Use private access controls and redact authorization headers in any proxy logs. The provider necessarily receives destination numbers and message content.

## Verification for this source change

`py -3 -m unittest discover -s scripts -p test_demo_sms_server.py -v`: 13 tests passed with a mocked provider and external URL requests forbidden. Covers authentication, allowlisting, approved copy, invalid identities/numbers/amounts, formatting, name-only skips, number-only recipients, concurrent requests, persistence across restart, changed snapshots and uncertain failures. A Windows SQLite handle leak found by the first run was fixed before the passing run.

Swift payload assertions were updated but not executed: Swift/Xcode are unavailable on this Windows machine. No live SMS, simulator check, IPA build, deployment or release was performed for this change.
