# Decision 444 — `NaN`, `Infinity` and `-Infinity` print as those words on wasm

The example divides by a float zero to make `Infinity`, negates it to make `-Infinity`, and divides zero by zero to make `NaN`. On wasm, as on commonJS, each prints as that word, both on its own line and inside a string template: `Infinity`, `-Infinity`, `NaN`, `Infinity and NaN`. OTP has no such floats. On erlang and beam the first division is the division-by-zero `panic` before any value exists, a departure of those two targets and not a formatting question.

Cells in this repository that also bear on it: `modules/decisions-taken/float_division_by_zero_panics_on_beam-675/cases/float_nan_infinity_words`, `modules/decisions-taken/float_division_by_zero_panics_on_beam-675/cases/float_division_by_zero_panic`.

[draft/main.bp](draft/main.bp)
