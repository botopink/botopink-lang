# Decision 777 — 721's list of raises met while folding loses "an index out of bounds": `xs[3]` answers `?T` (`null`, 63 as overtaken by 139) and raises nothing, so no fold can raise there; the raises that remain are a failed conversion, a missing key and a `panic` reached inside an `Any` function.

Reading an index past the end of an array is no raise: `xs[3]` answers `?T`, and `null` when the array has no item
there. So an index out of bounds is not among the raises a fold can meet at build. Those that remain are a failed
conversion, a missing key and a `panic` reached inside an `Any` function (721).

In the example `fourth` is an ordinary `Any` function, and every call in `main` has every input known at build, so each
is folded there. `fourth([1, 2, 3])` reads index 3 of a three-item array: the fold answers `null` and the build goes on,
so the program prints `true` and then `-1` for the `?? -1` fallback. `fourth([1, 2, 3, 4])` folds to `4`. Nothing is
refused at build and nothing raises at run time.

Cells that also bear on it: `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_dict` (an
index is a method call answering `?V`); the draft of `modules/decisions-taken/fold_raise_is_build_error-721` shows the
raise a fold still turns into a build error.

[draft/main.bp](draft/main.bp)
