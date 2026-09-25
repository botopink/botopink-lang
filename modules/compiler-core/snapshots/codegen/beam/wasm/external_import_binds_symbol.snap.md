----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "extension"),
  @External.Node("node:path", "extname")]
pub declare fn extname(p: string) -> string;

fn main() {
    @print(extname("docs/readme.md"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `extname` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :6:12
  │
6 │     @print(extname("docs/readme.md"));
  │            ^
```

