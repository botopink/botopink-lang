----- SOURCE
```botopink
val Point = type(x: i32, y: i32);
fn dist(p: Point) -> i32 { return p.x + p.norm(); }
```

----- SEMANTIC TOKENS
  (0,0) +3  keyword  "val"
  (0,4) +5  type [declaration]  "Point"
  (0,12) +4  keyword  "type"
  (0,17) +1  property  "x"
  (0,20) +3  type [defaultLibrary]  "i32"
  (0,25) +1  property  "y"
  (0,28) +3  type [defaultLibrary]  "i32"
  (1,0) +2  keyword  "fn"
  (1,3) +4  function [declaration]  "dist"
  (1,8) +1  parameter  "p"
  (1,11) +5  type  "Point"
  (1,21) +3  type [defaultLibrary]  "i32"
  (1,27) +6  keyword  "return"
  (1,34) +1  parameter  "p"
  (1,36) +1  property  "x"
  (1,40) +1  parameter  "p"
  (1,42) +4  method  "norm"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 3 9 0
  0 4 5 0 1
  0 8 4 9 0
  0 5 1 8 0
  0 3 3 0 4
  0 5 1 8 0
  0 3 3 0 4
  1 0 2 9 0
  0 3 4 4 1
  0 5 1 6 0
  0 3 5 0 0
  0 10 3 0 4
  0 6 6 9 0
  0 7 1 6 0
  0 2 1 8 0
  0 4 1 6 0
  0 2 4 5 0
