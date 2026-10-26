# Decision 20 — Is a pattern range inclusive?

The question was whether a range in a pattern includes its end. The answer that stands is the split decision 53 made
after this row: two spellings, each with one meaning wherever it is written. `0...9` in `digit`'s arm matches `0` and
`9` and leaves `10` to `_`. In a loop `0..3` stops before `3` and `0...3` reaches it, and a slice reads the same way:
`xs[0..2]` is the first two items, `xs[1...2]` the second and third. So the program prints `digit`, `digit`, `other`,
then `0 1 2`, then `0 1 2 3`, then `[10, 20]` and `[20, 30]`.

Cells that also bear on it: `modules/case/cases/case_range_value`, `modules/case/cases/case_range_and_guard`, `modules/loop/cases/loop_forms`,
`modules/index/cases/index_and_slice_sugar`, `modules/array/cases/array_range_and_repeat`.

[cases/range_has_one_spelling_dot_dot/src/main.bp](cases/range_has_one_spelling_dot_dot/src/main.bp)
