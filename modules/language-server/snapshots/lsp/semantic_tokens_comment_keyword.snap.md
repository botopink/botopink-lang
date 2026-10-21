----- SOURCE
```botopink
/// doc comment
val flag = true;
```

----- SEMANTIC TOKENS
  (0,0) +15  comment  "/// doc comment"
  (1,0) +3  keyword  "val"
  (1,4) +4  variable [declaration]  "flag"
  (1,11) +4  keyword  "true"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 15 10 0
  1 0 3 9 0
  0 4 4 7 1
  0 7 4 9 0
