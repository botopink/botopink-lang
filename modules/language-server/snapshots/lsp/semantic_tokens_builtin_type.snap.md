----- SOURCE
```botopink
fn parse(x: i32) -> @Result<i32, string> { return @ok(x); }
```

----- SEMANTIC TOKENS
  (0,0) +2  keyword  "fn"
  (0,3) +5  function [declaration]  "parse"
  (0,9) +1  parameter  "x"
  (0,12) +3  type [defaultLibrary]  "i32"
  (0,20) +7  type [defaultLibrary]  "@Result"
  (0,28) +3  type [defaultLibrary]  "i32"
  (0,33) +6  type [defaultLibrary]  "string"
  (0,43) +6  keyword  "return"
  (0,50) +3  function [defaultLibrary]  "@ok"
  (0,54) +1  parameter  "x"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 2 9 0
  0 3 5 4 1
  0 6 1 6 0
  0 3 3 0 4
  0 8 7 0 4
  0 8 3 0 4
  0 5 6 0 4
  0 10 6 9 0
  0 7 3 4 4
  0 4 1 6 0
