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

    // `zip` pairs the receiver's items with `other`'s by index, truncating to
    // the shorter array. Template form: erlang uses `lists:zipwith` with a
    // tuple constructor; node uses an inline `.map` with index lookup +
    // truncation. wat deferred — no native zip primitive (logged as a known
    // gap; falls through to the inline allow-list as today).
```

*from `interface Array`*
