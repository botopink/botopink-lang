----- SOURCE
```botopink
val Element = type() implement Renderable
fn plain(a: i32) -> i32 { return a; }
fn fails(a: i32) -> Result<i32, string> { return a; }
fn waits<T>(a: T) -> Task<T> { return a; }
fn hook(a: i32) -> Component<i32> { return a; }
fn seq() -> Iterator<i32> { yield 1; }
fn pulses() -> Stream<i32> { yield 1; }
fn takes(t: Task<i32>) -> i32[] { return [1]; }
fn opt() -> ?Task<i32> { return null; }
type Box(v: i32) {
    fn load(self: Self) -> Task<i32> { return self.v; }
}
```

----- SEMANTIC TOKENS
  (0,0) +3  keyword  "val"
  (0,4) +7  type [declaration]  "Element"
  (0,14) +4  keyword  "type"
  (0,21) +9  keyword  "implement"
  (0,31) +10  type [defaultLibrary]  "Renderable"
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
  (2,20) +6  type [defaultLibrary]  "Result"
  (2,27) +3  type [defaultLibrary]  "i32"
  (2,32) +6  type [defaultLibrary]  "string"
  (2,42) +6  keyword  "return"
  (2,49) +1  parameter  "a"
  (3,0) +2  keyword  "fn"
  (3,3) +5  function [declaration,async]  "waits"
  (3,9) +1  type [declaration]  "T"
  (3,12) +1  parameter  "a"
  (3,15) +1  type  "T"
  (3,21) +4  type [defaultLibrary]  "Task"
  (3,26) +1  type  "T"
  (3,31) +6  keyword  "return"
  (3,38) +1  parameter  "a"
  (4,0) +2  keyword  "fn"
  (4,3) +4  function [declaration,async]  "hook"
  (4,8) +1  parameter  "a"
  (4,11) +3  type [defaultLibrary]  "i32"
  (4,19) +9  type [defaultLibrary]  "Component"
  (4,29) +3  type [defaultLibrary]  "i32"
  (4,36) +6  keyword  "return"
  (4,43) +1  parameter  "a"
  (5,0) +2  keyword  "fn"
  (5,3) +3  function [declaration,async]  "seq"
  (5,12) +8  type [defaultLibrary]  "Iterator"
  (5,21) +3  type [defaultLibrary]  "i32"
  (5,28) +5  keyword  "yield"
  (6,0) +2  keyword  "fn"
  (6,3) +6  function [declaration,async]  "pulses"
  (6,15) +6  type [defaultLibrary]  "Stream"
  (6,22) +3  type [defaultLibrary]  "i32"
  (6,29) +5  keyword  "yield"
  (7,0) +2  keyword  "fn"
  (7,3) +5  function [declaration]  "takes"
  (7,9) +1  parameter  "t"
  (7,12) +4  type [defaultLibrary]  "Task"
  (7,17) +3  type [defaultLibrary]  "i32"
  (7,26) +3  type [defaultLibrary]  "i32"
  (7,34) +6  keyword  "return"
  (8,0) +2  keyword  "fn"
  (8,3) +3  function [declaration]  "opt"
  (8,13) +4  type [defaultLibrary]  "Task"
  (8,18) +3  type [defaultLibrary]  "i32"
  (8,25) +6  keyword  "return"
  (8,32) +4  keyword  "null"
  (9,0) +4  keyword  "type"
  (9,5) +3  type [declaration]  "Box"
  (9,9) +1  property  "v"
  (9,12) +3  type [defaultLibrary]  "i32"
  (10,4) +2  keyword  "fn"
  (10,7) +4  method [declaration,async]  "load"
  (10,12) +4  parameter  "self"
  (10,18) +4  type [defaultLibrary]  "Self"
  (10,27) +4  type [defaultLibrary]  "Task"
  (10,32) +3  type [defaultLibrary]  "i32"
  (10,39) +6  keyword  "return"
  (10,46) +4  parameter  "self"
  (10,51) +1  property  "v"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 3 9 0
  0 4 7 0 1
  0 10 4 9 0
  0 7 9 9 0
  0 10 10 0 4
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
  0 8 6 0 4
  0 7 3 0 4
  0 5 6 0 4
  0 10 6 9 0
  0 7 1 6 0
  1 0 2 9 0
  0 3 5 4 9
  0 6 1 0 1
  0 3 1 6 0
  0 3 1 0 0
  0 6 4 0 4
  0 5 1 0 0
  0 5 6 9 0
  0 7 1 6 0
  1 0 2 9 0
  0 3 4 4 9
  0 5 1 6 0
  0 3 3 0 4
  0 8 9 0 4
  0 10 3 0 4
  0 7 6 9 0
  0 7 1 6 0
  1 0 2 9 0
  0 3 3 4 9
  0 9 8 0 4
  0 9 3 0 4
  0 7 5 9 0
  1 0 2 9 0
  0 3 6 4 9
  0 12 6 0 4
  0 7 3 0 4
  0 7 5 9 0
  1 0 2 9 0
  0 3 5 4 1
  0 6 1 6 0
  0 3 4 0 4
  0 5 3 0 4
  0 9 3 0 4
  0 8 6 9 0
  1 0 2 9 0
  0 3 3 4 1
  0 10 4 0 4
  0 5 3 0 4
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
  0 9 4 0 4
  0 5 3 0 4
  0 7 6 9 0
  0 7 4 6 0
  0 5 1 8 0
