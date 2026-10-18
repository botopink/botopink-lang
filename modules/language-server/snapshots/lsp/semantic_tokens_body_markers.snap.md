----- SOURCE
```botopink
async fn one() -> Task<i32> { return 1; }
iter fn two() -> Iterator<i32> { yield 2; }
async iter fn three() -> Stream<i32> { yield 3; }
component fn Four() -> Component<i32> { return 4; }
fn f() -> Task<i32> {
    val g: fn(x: i32) -> Task<i32> = async { x -> await one() };
    val component = 1;
    val iter = 2;
    return await g(component + iter);
}
```

----- SEMANTIC TOKENS
  (0,0) +5  keyword  "async"
  (0,6) +2  keyword  "fn"
  (0,9) +3  function [declaration,async]  "one"
  (0,18) +4  type [defaultLibrary]  "Task"
  (0,23) +3  type [defaultLibrary]  "i32"
  (0,30) +6  keyword  "return"
  (1,0) +4  keyword  "iter"
  (1,5) +2  keyword  "fn"
  (1,8) +3  function [declaration,async]  "two"
  (1,17) +8  type [defaultLibrary]  "Iterator"
  (1,26) +3  type [defaultLibrary]  "i32"
  (1,33) +5  keyword  "yield"
  (2,0) +5  keyword  "async"
  (2,6) +4  keyword  "iter"
  (2,11) +2  keyword  "fn"
  (2,14) +5  function [declaration,async]  "three"
  (2,25) +6  type [defaultLibrary]  "Stream"
  (2,32) +3  type [defaultLibrary]  "i32"
  (2,39) +5  keyword  "yield"
  (3,0) +9  keyword  "component"
  (3,10) +2  keyword  "fn"
  (3,13) +4  function [declaration,async]  "Four"
  (3,23) +9  type [defaultLibrary]  "Component"
  (3,33) +3  type [defaultLibrary]  "i32"
  (3,40) +6  keyword  "return"
  (4,0) +2  keyword  "fn"
  (4,3) +1  function [declaration,async]  "f"
  (4,10) +4  type [defaultLibrary]  "Task"
  (4,15) +3  type [defaultLibrary]  "i32"
  (5,4) +3  keyword  "val"
  (5,8) +1  variable [declaration]  "g"
  (5,11) +2  keyword  "fn"
  (5,14) +1  parameter  "x"
  (5,17) +3  type [defaultLibrary]  "i32"
  (5,25) +4  type [defaultLibrary]  "Task"
  (5,30) +3  type [defaultLibrary]  "i32"
  (5,37) +5  keyword  "async"
  (5,45) +1  parameter  "x"
  (5,50) +5  keyword  "await"
  (5,56) +3  function  "one"
  (6,4) +3  keyword  "val"
  (6,8) +9  variable [declaration]  "component"
  (7,4) +3  keyword  "val"
  (7,8) +4  variable [declaration]  "iter"
  (8,4) +6  keyword  "return"
  (8,11) +5  keyword  "await"
  (8,17) +1  function  "g"
  (8,19) +9  variable  "component"
  (8,31) +4  variable  "iter"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 5 9 0
  0 6 2 9 0
  0 3 3 4 9
  0 9 4 0 4
  0 5 3 0 4
  0 7 6 9 0
  1 0 4 9 0
  0 5 2 9 0
  0 3 3 4 9
  0 9 8 0 4
  0 9 3 0 4
  0 7 5 9 0
  1 0 5 9 0
  0 6 4 9 0
  0 5 2 9 0
  0 3 5 4 9
  0 11 6 0 4
  0 7 3 0 4
  0 7 5 9 0
  1 0 9 9 0
  0 10 2 9 0
  0 3 4 4 9
  0 10 9 0 4
  0 10 3 0 4
  0 7 6 9 0
  1 0 2 9 0
  0 3 1 4 9
  0 7 4 0 4
  0 5 3 0 4
  1 4 3 9 0
  0 4 1 7 1
  0 3 2 9 0
  0 3 1 6 0
  0 3 3 0 4
  0 8 4 0 4
  0 5 3 0 4
  0 7 5 9 0
  0 8 1 6 0
  0 5 5 9 0
  0 6 3 4 0
  1 4 3 9 0
  0 4 9 7 1
  1 4 3 9 0
  0 4 4 7 1
  1 4 6 9 0
  0 7 5 9 0
  0 6 1 4 0
  0 2 9 7 0
  0 12 4 7 0
