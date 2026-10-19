# Decision 250 — † std's `io.random.bool()` is dropped, not renamed; `coin()` is the boolean draw

The example draws a hundred times from `io.random.coin()`, binding each draw as a `bool` and counting the heads. The count is always between 0 and 100, so the program prints `true`. `coin()` is the boolean draw. `io.random.bool()` is not another name for it: it is gone, and calling it is an unresolved name.

Cells in this repository that also bear on it: `modules/std_random_on_every_target`, `modules/comptime_random_seeded`.

[draft/main.bp](draft/main.bp)
