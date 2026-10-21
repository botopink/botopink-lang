----- SOURCE
```botopink
fn find(k: string) -> ?i32 { return null; }
val hit = find("a");
```

----- CODE ACTIONS in range (1,0)–(1,19)
  [quickfix] Add type annotation: ?i32
    in file:///test.bp
      (1,7)–(1,7) → ": ?i32"
