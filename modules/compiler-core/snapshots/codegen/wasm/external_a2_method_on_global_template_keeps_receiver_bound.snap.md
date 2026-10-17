----- SOURCE CODE -- main.bp
```botopink
#[@external(.Erlang("iolist_to_binary(io_lib:format(\"~p\", [$0]))"), .Node("JSON.stringify($0)"))]
declare fn stringify(value: i32) -> string;

fn main() {
    @print(stringify(42));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `stringify` has no implementation for the wasm backend
  ┌─ :5:12
  │
5 │     @print(stringify(42));
  │            ^
```

