----- SOURCE
```botopink
fn id(a: i32) { return a; }
   ↑
val r1 = id(1);
val r2 = id(2);
```

----- REFERENCES at (line 0, char 3)
  (0,3) → (0,5)
  (1,9) → (1,11)
  (2,9) → (2,11)
