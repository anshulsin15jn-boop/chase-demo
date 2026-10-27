# Reference interpretation

The eight private images represent seven screens. References 6 and 8 are entrance and final states of Confirmation. All originals remain outside the repository.

| Reference | Native view |
| --- | --- |
| 1 | AccountsHomeView |
| 2 | RecipientDirectoryView |
| 3 | PayTransferHubView |
| 4 | EnterAmountView |
| 5 | RecipientSearchView with native keyboard focus |
| 6 | ConfirmationView entrance |
| 7 | ReviewPaymentView |
| 8 | ConfirmationView final state |

## Shared design

Style defines pale gray surfaces, a navy to blue header gradient, primary blue, gray supporting text, purple recipient badges, teal success, 20 point content insets, and 13 point card corners. Native system fonts use explicit sizes and weights corresponding to the references. Shared components include navigation headers, recipient identities, avatar badges, divided menu rows, primary buttons, and the floating rounded tab bar.

The root navigation bar is hidden during the payment flow. System status bars, safe areas, and keyboards remain native. Scrollable forms and keyboard dismissal keep controls reachable on smaller phones. The application uses the light appearance.

## Recorded approximations

Product illustrations and specialized banking line art use SF Symbols. Recipient registration now uses one custom SwiftUI z shape with crossing strokes, scaled to 32 percent of its avatar and placed on a small white backing at the lower-right edge. The Siri demonstration uses a drawn multicolor orb with gradients and curved highlights, not a waveform symbol. These vectors recreate the references without embedding screenshot pixels; the Siri orb remains a visual approximation. Text wraps vary with name lengths and iOS font rendering. No image compression or accidental transition blur is baked into the views.

## State boundaries

DemoCore contains exact integer cent input, validation, synthetic fixtures, searching, a value type ledger, optional local profile, backward-compatible persistence, and immutable submitted payment records. DemoStore owns root selection, typed routes, recipients, draft, selected account and the last submitted snapshot. Views read that store and dispatch actions. Normal launches use the actual device clock and local calendar. Tests inject deterministic dates. Default Today rolls forward; explicitly selected calendar dates do not. Foreground and significant clock changes refresh the state, and submission validates the current day again.

Scheduled records preserve the chosen date without changing balances. Immediate payments deduct once. The asynchronous submit guard and ledger submission ID prevent duplicate records. A repeating payment records a frequency but never executes background payments.
