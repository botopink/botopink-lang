----- SOURCE CODE -- main.bp
```botopink
#[@external(.Erlang("filename:extension($0)"), .Node("""require("node:path").extname($0)"""))]
pub declare fn extname(p: string) -> string;

fn main() {
    @print(extname("docs/readme.md"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `extname` has no implementation for the wasm backend
  ┌─ :5:12
  │
5 │     @print(extname("docs/readme.md"));
  │            ^
```

