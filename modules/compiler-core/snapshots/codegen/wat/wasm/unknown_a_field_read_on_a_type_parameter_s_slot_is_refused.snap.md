----- SOURCE CODE -- main.bp
```botopink
type Maybe<T> {
    Some(value: T),
    None,
}
fn innerLength(b: unknown) -> i32 {
    return case b {
        Maybe.Some(value: v) when (v is string) { v.length }
        Maybe.Some(value: v) { -1 }
        _ { -2 }
    };
}
fn main() {
    val s: unknown = Maybe.Some(value: "abc");
    @print(innerLength(s));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: the wasm backend cannot place `.length`: the receiver's type is not known here
  ┌─ :7:53
  │
7 │         Maybe.Some(value: v) when (v is string) { v.length }
  │                                                     ^
```

