> Decision 575 (4) — `-> expr T` is a template's return: the expression
> returned is spliced at the call. A `comptime` parameter's value computed
> at build is spliced as a literal (`shout`); an `expr` parameter hands the
> expression written on (`same`).
