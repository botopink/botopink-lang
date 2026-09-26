----- SOURCE
```botopink
val Element = type() implement @Context<Element>
fn plain(a: i32) -> i32 { return a; }
fn fails(a: i32) -> @Result<i32, string> { return a; }
fn waits<T>(a: T) -> @Task<T> { return a; }
fn hook(a: i32) -> @Component<Element, i32> { a; }
fn seq() -> @Iterator<i32> { yield 1; }
fn pulses() -> @Stream<i32> { yield 1; }
fn takes(t: @Task<i32>) -> i32[] { return [1]; }
fn opt() -> ?@Task<i32> { return null; }
type Box(v: i32) {
    fn load(self: Self) -> @Task<i32> { return self.v; }
}
```

----- SEMANTIC TOKENS
  (0,0) +3  keyword  "val"
  (0,4) +7  type [declaration]  "Element"
  (0,14) +4  keyword  "type"
  (0,21) +9  keyword  "implement"
  (0,31) +8  type [defaultLibrary]  "@Context"
  (0,40) +7  type  "Element"
  (1,0) +2  keyword  "fn"
  (1,3) +5  function [declaration]  "plain"
  (1,9) +1  parameter  "a"
  (1,12) +3  type [defaultLibrary]  "i32"
  (1,20) +3  type [defaultLibrary]  "i32"
  (1,26) +6  keyword  "return"
  (1,33) +1  parameter  "a"
  (2,0) +2  keyword  "fn"
  (2,3) +5  function [declaration,async]  "fails"
  (2,9) +1  parameter  "a"
  (2,12) +3  type [defaultLibrary]  "i32"
  (2,20) +7  type [defaultLibrary]  "@Result"
  (2,28) +3  type [defaultLibrary]  "i32"
  (2,33) +6  type [defaultLibrary]  "string"
  (2,43) +6  keyword  "return"
  (2,50) +1  parameter  "a"
  (3,0) +2  keyword  "fn"
  (3,3) +5  function [declaration,async]  "waits"
  (3,9) +1  type [declaration]  "T"
  (3,12) +1  parameter  "a"
  (3,15) +1  type  "T"
  (3,21) +5  type [defaultLibrary]  "@Task"
  (3,27) +1  type  "T"
  (3,32) +6  keyword  "return"
  (3,39) +1  parameter  "a"
  (4,0) +2  keyword  "fn"
  (4,3) +4  function [declaration,async]  "hook"
  (4,8) +1  parameter  "a"
  (4,11) +3  type [defaultLibrary]  "i32"
  (4,19) +10  type [defaultLibrary]  "@Component"
  (4,30) +7  type  "Element"
  (4,39) +3  type [defaultLibrary]  "i32"
  (4,46) +1  parameter  "a"
  (5,0) +2  keyword  "fn"
  (5,3) +3  function [declaration,async]  "seq"
  (5,12) +9  type [defaultLibrary]  "@Iterator"
  (5,22) +3  type [defaultLibrary]  "i32"
  (5,29) +5  keyword  "yield"
  (6,0) +2  keyword  "fn"
  (6,3) +6  function [declaration,async]  "pulses"
  (6,15) +7  type [defaultLibrary]  "@Stream"
  (6,23) +3  type [defaultLibrary]  "i32"
  (6,30) +5  keyword  "yield"
  (7,0) +2  keyword  "fn"
  (7,3) +5  function [declaration]  "takes"
  (7,9) +1  parameter  "t"
  (7,12) +5  type [defaultLibrary]  "@Task"
  (7,18) +3  type [defaultLibrary]  "i32"
  (7,27) +3  type [defaultLibrary]  "i32"
  (7,35) +6  keyword  "return"
  (8,0) +2  keyword  "fn"
  (8,3) +3  function [declaration]  "opt"
  (8,13) +5  type [defaultLibrary]  "@Task"
  (8,19) +3  type [defaultLibrary]  "i32"
  (8,26) +6  keyword  "return"
  (8,33) +4  keyword  "null"
  (9,0) +4  keyword  "type"
  (9,5) +3  type [declaration]  "Box"
  (9,9) +1  property  "v"
  (9,12) +3  type [defaultLibrary]  "i32"
  (10,4) +2  keyword  "fn"
  (10,7) +4  method [declaration,async]  "load"
  (10,12) +4  parameter  "self"
  (10,18) +4  type [defaultLibrary]  "Self"
  (10,27) +5  type [defaultLibrary]  "@Task"
  (10,33) +3  type [defaultLibrary]  "i32"
  (10,40) +6  keyword  "return"
  (10,47) +4  parameter  "self"
  (10,52) +1  property  "v"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 3 9 0
  0 4 7 0 1
  0 10 4 9 0
  0 7 9 9 0
  0 10 8 0 4
  0 9 7 0 0
  1 0 2 9 0
  0 3 5 4 1
  0 6 1 6 0
  0 3 3 0 4
  0 8 3 0 4
  0 6 6 9 0
  0 7 1 6 0
  1 0 2 9 0
  0 3 5 4 9
  0 6 1 6 0
  0 3 3 0 4
  0 8 7 0 4
  0 8 3 0 4
  0 5 6 0 4
  0 10 6 9 0
  0 7 1 6 0
  1 0 2 9 0
  0 3 5 4 9
  0 6 1 0 1
  0 3 1 6 0
  0 3 1 0 0
  0 6 5 0 4
  0 6 1 0 0
  0 5 6 9 0
  0 7 1 6 0
  1 0 2 9 0
  0 3 4 4 9
  0 5 1 6 0
  0 3 3 0 4
  0 8 10 0 4
  0 11 7 0 0
  0 9 3 0 4
  0 7 1 6 0
  1 0 2 9 0
  0 3 3 4 9
  0 9 9 0 4
  0 10 3 0 4
  0 7 5 9 0
  1 0 2 9 0
  0 3 6 4 9
  0 12 7 0 4
  0 8 3 0 4
  0 7 5 9 0
  1 0 2 9 0
  0 3 5 4 1
  0 6 1 6 0
  0 3 5 0 4
  0 6 3 0 4
  0 9 3 0 4
  0 8 6 9 0
  1 0 2 9 0
  0 3 3 4 1
  0 10 5 0 4
  0 6 3 0 4
  0 7 6 9 0
  0 7 4 9 0
  1 0 4 9 0
  0 5 3 0 1
  0 4 1 8 0
  0 3 3 0 4
  1 4 2 9 0
  0 3 4 5 9
  0 5 4 6 0
  0 6 4 0 4
  0 9 5 0 4
  0 6 3 0 4
  0 7 6 9 0
  0 7 4 6 0
  0 5 1 8 0
