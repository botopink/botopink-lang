----- SOURCE
```botopink
pub fn component(comptime decl: @Decl) {
    var args = "";
    items.forEach({ f ->
        log(args);
        ↑
    });
}
```

----- COMPLETION at (line 3, char 8)
f  [Variable]  detail: binder
args  [Variable]  detail: local
decl  [Variable]  detail: parameter
