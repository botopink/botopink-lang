# fn_tail_in_void

The reference text this cell shows (from `conformance/docs.md`, § fn — function):

> A function body's last expression written without `;` is its value (decision 409) — in every
> body: a named `fn`, a method, a function expression and a lambda. `fn inc(x: i32) -> i32 { x + 1 }`;
> an early `return` stays (`fn sign(n: i32) -> i32 { if (n < 0) return -1; n }`), and every `return
> x;` stays valid. With `;` it is a statement, and a body with `-> R` then needs a `return` — `fn
> semi(x: i32) -> i32 { x + 1; }` is refused at `-> i32` as above. A braced `if` / `case` / loop at the
> end is a statement, never the tail. The tail is checked against `-> R` at the expression; in a body
> answering nothing (no `-> R`, or `-> void`), a tail of another type is refused at it.
> `botopink format` neither adds nor removes the tail's missing `;`, and prints a body of one tail on
> one line when it fits:
