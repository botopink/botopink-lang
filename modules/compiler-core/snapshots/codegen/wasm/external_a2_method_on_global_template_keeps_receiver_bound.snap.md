----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("iolist_to_binary(io_lib:format(\"~p\", [$0]))"),
  @External.Node("JSON.stringify($0)")]
declare fn stringify(value: i32) -> string;

fn main() {
    @print(stringify(42));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `stringify` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :6:12
  │
6 │     @print(stringify(42));
  │            ^
```

