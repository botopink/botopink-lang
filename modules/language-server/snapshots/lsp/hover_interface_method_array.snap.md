----- SOURCE
```botopink
val xs = [1, 2, 3];
val y = xs.filter({ x -> true });
            ↑
```

----- HOVER at (line 1, char 12)
kind: markdown

```botopink
fn filter(self: Self, pred: fn(item: T) -> bool) -> Self

    // ── producers (associated — no receiver) ──
    // Pure botopink (no host backing): the host `lists:seq`/`duplicate` have the
    // wrong semantics (`seq` is end-inclusive; `duplicate` swaps the args), so
    // these recurse with an array-literal spread `[head, ..tail]`, giving
    // identical end-exclusive `[start, stop)` / `times`-copy results on every
    // backend. `head` is bound to a `val` first so the BEAM backend spills it to a
    // stack slot — an x-register would be clobbered by the recursive call. (No
    // comments inside the bodies: the commonJS if-expr emits as a one-line IIFE,
    // where a `//` would swallow the rest of the block.)
    default
```

*from `interface Array`*
