----- SOURCE CODE -- main.bp
```botopink
#[@external(.Erlang("base64:encode($0)"), .Node("""Buffer.from($0, 'utf8').toString('base64')"""))]
pub declare fn b64encode(s: string) -> string;

fn main() {
    @print(b64encode("hi"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `b64encode` has no implementation for the wasm backend
  ┌─ :5:12
  │
5 │     @print(b64encode("hi"));
  │            ^
```

