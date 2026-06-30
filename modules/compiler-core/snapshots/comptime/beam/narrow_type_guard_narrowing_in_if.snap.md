----- SOURCE CODE -- main.bp
```botopink
fn isString(x: ?string) -> x is string {
    if (x) { _ -> return true; };
    return false;
}
@print(isString("hello"));
```

