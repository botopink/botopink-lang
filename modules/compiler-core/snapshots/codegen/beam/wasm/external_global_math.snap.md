----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("math", "floor"),
  @External.Node("Math", "floor")]
pub declare fn floor(n: f64) -> f64;

fn main() {
    @print(floor(1.7));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `floor` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :6:12
  │
6 │     @print(floor(1.7));
  │            ^
```

