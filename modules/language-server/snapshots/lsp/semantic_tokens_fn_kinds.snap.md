----- SOURCE
```botopink
fn free(a: i32) -> i32 { return a; }
interface Greeter { fn greet(self: Self) -> string }
#[@iterator]
fn counter() -> @Iterator<i32> :gen { yield 1; }
```

----- SEMANTIC TOKENS
  (0,0) +2  keyword  "fn"
  (0,3) +4  function [declaration]  "free"
  (0,8) +1  parameter  "a"
  (0,11) +3  type [defaultLibrary]  "i32"
  (0,19) +3  type [defaultLibrary]  "i32"
  (0,25) +6  keyword  "return"
  (0,32) +1  variable  "a"
  (1,0) +9  keyword  "interface"
  (1,10) +7  interface [declaration]  "Greeter"
  (1,20) +2  keyword  "fn"
  (1,23) +5  method [declaration]  "greet"
  (1,29) +4  parameter  "self"
  (1,35) +4  type [defaultLibrary]  "Self"
  (1,44) +6  type [defaultLibrary]  "string"
  (2,2) +9  function [defaultLibrary]  "@iterator"
  (3,0) +2  keyword  "fn"
  (3,3) +7  function [declaration]  "counter"
  (3,16) +9  type [defaultLibrary]  "@Iterator"
  (3,26) +3  type [defaultLibrary]  "i32"
  (3,32) +3  variable  "gen"
  (3,38) +5  keyword  "yield"
