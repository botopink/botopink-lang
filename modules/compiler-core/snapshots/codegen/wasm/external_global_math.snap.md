----- SOURCE CODE -- main.bp
```botopink
#[@external(.Erlang("math:floor($0)"), .JavaScript("Math.floor($0)"))]
pub declare fn floor(n: f64) -> f64;

fn main() {
    @print(floor(1.7));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `floor` has no implementation for the wasm backend
  ┌─ :5:12
  │
5 │     @print(floor(1.7));
  │            ^
```

