# Decision 596 — `Iter<T, R>` declares the iterator helpers whole, typed, on every target: `take`, `drop`, `map`, `filter`, `flatMap`, `forEach`, `toArray`, `reduce`, `some`, `every`, `find`.

The example uses one infinite generator, `naturals`, and calls every helper `Iter` declares on it. `drop(1).take(5)` gives `[1, 2, 3, 4, 5]`. `map` squares to `[0, 1, 4, 9, 16]`. `filter` keeps the evens, `[0, 2, 4]`. `flatMap` over the generator `twice` gives `[0, 0, 1, 10, 2, 20]`. `forEach` prints `item 0` and `item 1`. `reduce` sums to `10`. `some` answers `true` and `every` answers `false`. `find` answers the first square above 50, `8`, as a `?i32`. Every helper is typed on `Iter<T, R>` itself and is lazy over an infinite source, so the same lines print on every target.

Cells in this repository that also bear on it: `modules/generator/cases/generator_to_array_printed`, `modules/iterator/cases/iterator_method`.

[draft/main.bp](draft/main.bp)
