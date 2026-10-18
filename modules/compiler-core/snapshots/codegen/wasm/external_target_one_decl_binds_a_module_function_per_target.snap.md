----- SOURCE CODE -- main.bp
```botopink
#[@external(.Erlang("filename:dirname($0)"), .JavaScript("""require("node:path").dirname($0)"""))]
pub declare fn dirname(p: string) -> string;

fn main() {
    @print(dirname("/tmp/notes.txt"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `dirname` has no implementation for the wasm backend
  ┌─ :5:12
  │
5 │     @print(dirname("/tmp/notes.txt"));
  │            ^
```

