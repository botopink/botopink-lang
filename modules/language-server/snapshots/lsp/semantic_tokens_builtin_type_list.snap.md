----- SOURCE
```botopink
fn f(a: i32, b: unknown, c: never) { }
```

----- SEMANTIC TOKENS
  (0,0) +2  keyword  "fn"
  (0,3) +1  function [declaration]  "f"
  (0,5) +1  parameter  "a"
  (0,8) +3  type [defaultLibrary]  "i32"
  (0,13) +1  parameter  "b"
  (0,16) +7  type [defaultLibrary]  "unknown"
  (0,25) +1  parameter  "c"
  (0,28) +5  variable  "never"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 2 9 0
  0 3 1 4 1
  0 2 1 6 0
  0 3 3 0 4
  0 5 1 6 0
  0 3 7 0 4
  0 9 1 6 0
  0 3 5 7 0
