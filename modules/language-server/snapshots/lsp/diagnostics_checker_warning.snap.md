----- SOURCE
```botopink
pub fn main() {
    var out = [];
    @print("x");
}
```

----- DIAGNOSTICS
(1,4)–(1,5)  warning  `out` is born with no element type — annotate it: `var out: unknown[] = [];`
