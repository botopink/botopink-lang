----- SOURCE CODE -- main.bp
```botopink
fn greet(x: ?string) -> string {
    if (!x) { return "nobody"; };
    return "hello " + x;
}
@print(greet("world"));
```

