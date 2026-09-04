# OTP field backspace bug — investigation report

**Widget:** `PasswordResetOtpField` in `lib/pages/password_reset/password_reset_ui.dart`
**Report:** holding backspace on the six-box code field on the password-recovery
screen does not delete properly; feels like six separate fields.
**Branch:** `investigate/otp-backspace-hu20`
**Result:** did NOT reproduce the defect. No production code was changed.
Regression tests were added and committed:
`test/HU20_jeff/password_reset_otp_field_backspace_test.dart` (commit `f93ba66`).

## What I tried

All scenarios use `WidgetTester` with `tester.testTextInput.updateEditingValue(...)`,
which is the actual channel the engine uses to deliver each platform edit to
the framework (as opposed to `tester.enterText`, which replaces the whole
value at once and cannot emulate an incremental, held key). Every scenario
starts from a `PasswordResetOtpField` wired to a real `TextEditingController`,
pumped and focused first.

### 1. Baseline typing

Sent `"1"`, `"12"`, ..., `"123456"` one at a time, each with selection
collapsed at the new end, `pump()` between each. Confirms typing works and
sets the stage identically to how a real user fills the field.

Result: `controller.text` and `controller.selection` matched exactly at every
step. No surprises.

### 2. Held backspace, animations allowed to settle

Starting from `"123456"`, sent the sequence `"12345"`, `"1234"`, `"123"`,
`"12"`, `"1"`, `""`, each with selection collapsed at the new end, with
`pumpAndSettle()` between every value (so the `AnimatedContainer`'s 120ms
border-highlight transition always finishes before the next event).

Result: `controller.text` equaled the expected value after every single
step, ending at `""`. No digit was skipped, restored, or left over.

### 3. Held backspace, animations NOT allowed to settle

Same sequence as #2, but only `await tester.pump(const Duration(milliseconds: 16))`
between updates — deliberately faster than the `AnimatedContainer`'s 120ms
duration and faster than a realistic key-repeat interval, to test the
project owner's specific worry that the animation/rebuild cadence interferes
with a fast held key.

Result: identical to #2 — every intermediate value was exactly right, final
value `""`. This is the test that most directly targets "held key faster
than the animation."

### 4. Fully synchronous burst, no `pump()` between calls at all

Fired all six `updateEditingValue` calls back-to-back with zero `pump()`
calls in between (only `pumpAndSettle()` at the very end) — the extreme case
of "platform faster than the Flutter frame pipeline." Because
`updateEditingValue` invokes the framework's callback synchronously in the
test harness, `controller.text` was already correct immediately after each
call, before any frame was even requested.

Result: correct at every step, final value `""`.

### 5. Tap into the middle, then delete

Sent `TextEditingValue(text: "123456", selection: collapsed(offset: 3))` to
simulate the platform reporting a mid-field tap with no text change. This is
the one case flagged in the investigation brief as the only place where
`_handleValueChanged`'s guard (`if (widget.controller.selection != endSelection)`)
actually fires and writes back to the controller, since a plain end-of-field
delete already arrives with `selection == endSelection` (a no-op, confirming
the original hypothesis doubt was correct).

Result: the guard does fire and forces `controller.selection` back to
`collapsed(offset: 6)` — the text stays `"123456"`, unchanged. This is a
real, confirmed behavior (tapping a middle box does not let you position a
cursor there — it snaps back to the end), and it matches the widget's own
doc comment ("Mantiene el cursor al final para que escribir siempre agregue
el siguiente dígito"), so it looks intentional, not the reported bug. A
backspace sent immediately after this still correctly removed the last real
digit (`"123456"` → `"12345"`).

### 6. Stale/duplicate echo interleaved with deletes (extra, not committed as a permanent test)

To stress-test the "acts resistant to deleting" complaint from a different
angle, I interleaved a stale re-send of the older, longer value into a
deletion sequence: `"123456"` → `"12345"` → **`"123456"` again (a duplicate/
late echo of the pre-delete value)** → `"12345"` → `"1234"`.

Result: the controller simply mirrors whatever value it's told last —
`"123456"` reappeared when re-sent, then the deletions continued correctly
from there. This shows the widget has no defense against genuinely
out-of-order platform messages, but also that nothing in its own code
reorders or drops messages; it's a faithful mirror. I did not keep this as a
permanent regression test because I have no evidence real iOS/Android
delivery is out-of-order on a single method channel — it was purely
exploratory. Not committed.

### 7. Notification-count instrumentation

Attached a second listener to the controller that counts `notifyListeners()`
calls, then repeated the type and delete sequences.

Result: exactly one notification per `updateEditingValue` call, both while
typing and while deleting. No double-firing, no extra rebuild storms visible
at the data layer.

## Conclusion

I could not reproduce the reported defect with `WidgetTester`. In every
scenario — settled animations, unsettled/fast animations, a fully
synchronous burst faster than the frame pipeline, and the one case where the
selection-forcing guard actually engages — the controller's text ends up
exactly correct after each simulated platform update: N deletions produce N
fewer characters, in order, nothing skipped, nothing restored. The one
originally-suspected mechanism (the guard fighting the platform's selection)
turns out to be a no-op for plain end-of-field deletion, exactly as the
investigation brief's own doubt predicted, and it does not touch the text in
the one case where it *does* write something back.

**I am not shipping the previously-considered defensive change** ("only
repaint when text changed" + "move cursor to end only on focus-gain")
because I found no evidence it fixes anything — that would be a speculative
behavior change against explicit instructions not to make one without
reproduction.

### What I'd need to actually reproduce this

`tester.testTextInput` decouples the test from everything that differs
between it and a real device:

- **Real IME repeat-key timing/acceleration.** iOS's on-screen keyboard
  backspace has its own hold-to-repeat acceleration (and, after ~0.5s, an
  UIKit-driven "expand selection then delete" visual/behavioral mode) that is
  implemented natively and queries the app's `UIKeyInput`/`UITextInput`
  conformance (`hasText`, `deleteBackward`, `caretRect(for:)`, etc.). None of
  that native code runs in a widget test; `updateEditingValue` only emulates
  the *data* the engine would eventually deliver to Dart, not the native
  request/response choreography that produces it.
- **`showCursor: false` / `cursorWidth: 0`.** These affect what caret
  geometry Flutter reports back to the platform via the text input channel.
  If iOS's repeat-delete acceleration UI leans on caret rect queries (it
  does, for the "growing selection" effect during a long hold), a
  degenerate/zero-width caret could plausibly confuse that native behavior
  in a way this test harness has no code path to exercise at all — there is
  no fake "platform" here consuming caret geometry.
- **Real rendering/rasterization jank.** `setState()` unconditionally on
  every notification (even a pure selection-only one) forces a rebuild of
  the `Stack`/`Row` of six `AnimatedContainer`s. In the test harness this
  costs nothing measurable; on a real device, if that rebuild is slow enough
  relative to the native repeat interval, the *symptom* would be perceived
  lag/"feels resistant to deleting" even though the underlying data is
  correct at every step — which matches "tiene buena UX pero falla cuando
  uno quiere borrar... se siente raro" better than a hard data-loss bug does.
  This would need a profiled run on the actual iPhone SE target device (or
  at least a real iOS Simulator) to confirm or rule out; I did not have
  permission to drive the simulator in this session.

If a real device is available, I'd recommend recording the OTP field while
holding backspace with the Flutter DevTools performance overlay (or
`flutter run --profile` + timeline) visible, specifically watching whether
frames are being dropped during the hold — that would either confirm the
rendering-jank theory or rule it out, and is the fastest next step.

## What changed in the code

Nothing in `lib/pages/password_reset/password_reset_ui.dart`. Only test
coverage was added:

- `test/HU20_jeff/password_reset_otp_field_backspace_test.dart` — 6 tests
  covering: baseline typing, settled held-backspace, unsettled/fast
  held-backspace, fully synchronous rapid-fire backspace, mid-field-tap then
  delete, and per-update notification count. All pass against the current,
  unmodified widget. `flutter analyze` shows only pre-existing info-level
  issues in unrelated files (0 issues in the new test file, 0 errors
  anywhere).
