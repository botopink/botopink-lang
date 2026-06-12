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
  (0,54) +1  variable  "x"
