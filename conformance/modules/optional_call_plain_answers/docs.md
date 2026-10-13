# optional_call_plain_answers

`f?.(args)` over a `?fn(…) -> T` with a plain `T` is a `?T`: absent when the function is, the
function's answer otherwise — a present `0` stays present — for an integer, a string, a bool and a
record answer, on every target (decision 330).
