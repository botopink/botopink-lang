----- SOURCE
```botopink
val decl = 99;
pub fn component(syntax decl: unknown) -> void {
    var args = "";
    items.forEach({ f ->
        use(decl, args, f);
                        ↑
    });
}
```

----- DEFINITION at (line 4, char 24)
uri: file:///test.bp
range: (3,20) → (3,21)
      items.forEach({ f ->
                      ^
