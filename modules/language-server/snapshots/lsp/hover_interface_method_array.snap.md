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
```

*from `behavior Array`*
