----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "basename"),
  @External.Node("node:path", "basename")]
pub declare fn basename(p: string) -> string;

fn main() {
    @print(basename("/tmp/notes.txt"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `basename` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :6:12
  │
6 │     @print(basename("/tmp/notes.txt"));
  │            ^
```

