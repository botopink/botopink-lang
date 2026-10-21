# prelude_has_no_pair_or_function

Decision 738: neither `Pair<A, B>` nor `Function` is a name of the prelude. A pair is the tuple `#(A, B)` — `#(1, "x")`
builds one, `p._1` and `val #(n, _) = p` read it — and the function combinators `identity`, `compose`, `flip` and
`constant` are plain functions of std's `functions` module, imported by path (`import {functions.compose} from "std";`).
`Pair.of(1, "x")` is refused at `Pair`, the message naming the tuple `#(A, B)`; it used to build the tuple through the
prelude's `Pair` behavior.
