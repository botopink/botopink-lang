# marker_lambda_async

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> Before a lambda's brace the marker makes a marked lambda — `async { x -> …
> }`, `iter { n -> … }`, `async iter { n -> … }` — and before `fn(…)` a marked
> function expression; `->` tells the lambda from the block forms `async { …
> }` and `iter loop { … }`. A marked lambda is typed by the function type it
> is written for (decision 147): an annotated `val`, a parameter. It answers
> what the lambda returning the block form would — `async { x -> b }` is `{ x
> -> async { b } }`, `iter { x -> b }` is `{ x -> iter loop { b; break; } }`.
