----- SOURCE CODE -- main.bp
```botopink
#[@External.Node("process.pid"),
  @External.Erlang("list_to_integer(os:getpid())")]
declare fn pid() -> i32;

fn main() {
    @print(pid() > 0);
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `pid` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :6:12
  │
6 │     @print(pid() > 0);
  │            ^
```

