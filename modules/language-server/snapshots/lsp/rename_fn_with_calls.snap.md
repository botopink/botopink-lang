----- SOURCE
```botopink
fn f(a: i32) { return a; }
   ↑
val r = f(1);
```

----- RENAME at (line 0, char 3)  new name: "identity"
  edit 1: (0,3) → (0,4)  "identity"
  edit 2: (1,8) → (1,9)  "identity"
