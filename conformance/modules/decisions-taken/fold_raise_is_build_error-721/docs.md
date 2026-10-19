# Decision 721 — (a): every raise met while folding an expression at build is a build error at the expression — an index out of bounds, a failed conversion, a missing key, a `panic` reached inside an `Any` function — as 380 (2) writes; nothing that raised at build is left to the run time.

In the example, `checked` is an ordinary `Any` function that panics above 2. Both calls in `main` have every input known at build, so both are folded there. `checked(2)` folds to the constant `20`. `checked(5)` reaches the `panic` while it is being folded, and that raise is a build error at the expression `checked(5)`, with the text the target would print. It is not left behind as a run-time crash. The program is therefore refused at build and never prints `20`. A `panic` written directly in `main`, with no `comptime`, would not be folded at all. The rule here covers raises met inside a fold.

Cells in this repository that also bear on it: `modules/comptime_primitives_at_build`.

[draft/main.bp](draft/main.bp)
