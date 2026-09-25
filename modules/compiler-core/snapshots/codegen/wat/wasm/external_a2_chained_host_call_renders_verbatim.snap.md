----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("base64:encode($0)"),
  @External.Node("""Buffer.from($0, 'utf8').toString('base64')""")]
pub declare fn b64encode(s: string) -> string;

fn main() {
    @print(b64encode("hi"));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `b64encode` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :6:12
  │
6 │     @print(b64encode("hi"));
  │            ^
```

