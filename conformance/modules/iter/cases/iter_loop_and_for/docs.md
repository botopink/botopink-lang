# iter_loop_and_for

The reference text this cell shows (from `conformance/docs.md`, § Loops):

> **`yield v` and `break v` need a generator scope** — a function whose return is
> `Iter<T>` or `AsyncIter<T>`, or an `iter` / `stream` loop. `yield v` emits
> and continues; `break v` emits and ends (≡ `yield v; break;`). Outside a
> generator scope both are refused: no plain loop answers a value, and collecting
> in an ordinary function is `xs.map(…)` / `filter(…)` or a `var`. A `yield`
> inside an unprefixed `for`, `while` or `loop` feeds the **nearest** generator
> scope; `yield :label v` and `break :label v` name another scope's label.
>
> With `iter` or `stream` in front, the loop is an expression worth the iterator
> (or the stream), `T` being the type of its `yield` / `break v`. It captures the
> enclosing scope — a `var` it reassigns is its state:
