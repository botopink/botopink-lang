----- SOURCE CODE -- main.bp
```botopink
#[@external(.Erlang("filename:basename($0)"), .Node("""require("node:path").basename($0)"""))]
pub declare fn basename(p: string) -> string;

fn main() {
    @print(basename("/tmp/notes.txt"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `basename` has no implementation for the wasm backend
  ┌─ :5:12
  │
5 │     @print(basename("/tmp/notes.txt"));
  │            ^
```

