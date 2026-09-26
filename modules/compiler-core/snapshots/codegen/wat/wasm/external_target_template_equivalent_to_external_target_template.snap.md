----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "dirname"),
  @External.Node("node:path", "dirname")]
pub declare fn dirname(p: string) -> string;

fn main() {
    @print(dirname("/tmp/notes.txt"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `dirname` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :6:12
  │
6 │     @print(dirname("/tmp/notes.txt"));
  │            ^
```

