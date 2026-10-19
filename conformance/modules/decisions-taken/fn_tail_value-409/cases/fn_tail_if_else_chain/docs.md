# fn_tail_if_else_chain

The reference text this cell shows (from `conformance/docs.md`, § fn — function):

> An early `return` from inside a loop or a `case` arm leaves the function, and the tail is its value
> on every other path; an `if` / `else if` / `else` expression is a tail like any other, and a tail
> may name a `case` bound by a `val` before it. A method answering nothing refuses a tail of another
> type as a free function does; a `void` tail — a call answering nothing — is accepted in a function,
> a method and a lambda that answer nothing. A tail is the function's value wherever its body runs:
> at compile time (`comptime square(3)`), and in a function answering `Result<T, E>`, where it is
> the `T` as `return value;` is:
