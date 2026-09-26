----- SOURCE
```botopink
import {async} from "std";
fn f(xs: i32[], g: Grid, http: Http) -> @Task<i32> {
    val t = async { return 1; };
    val all = async.allOf([t]);
    val a = iter loop { yield 1; break; };
    val b = iter for :outer (xs) { x -> if (x > 1) { break :outer; }; yield x; };
    val c = stream while (true) { yield 1; };
    val d = stream for await (s) { x -> yield x; };
    val stream = 1;
    val iter = g.iter();
    val body = http.stream(stream);
    return await t;
}
```

----- SEMANTIC TOKENS
  (0,0) +6  keyword  "import"
  (0,8) +5  variable  "async"
  (0,15) +4  keyword  "from"
  (1,0) +2  keyword  "fn"
  (1,3) +1  function [declaration,async]  "f"
  (1,5) +2  parameter  "xs"
  (1,9) +3  type [defaultLibrary]  "i32"
  (1,16) +1  parameter  "g"
  (1,19) +4  variable  "Grid"
  (1,25) +4  parameter  "http"
  (1,31) +4  variable  "Http"
  (1,40) +5  type [defaultLibrary]  "@Task"
  (1,46) +3  type [defaultLibrary]  "i32"
  (2,4) +3  keyword  "val"
  (2,8) +1  variable [declaration]  "t"
  (2,12) +5  keyword  "async"
  (2,20) +6  keyword  "return"
  (3,4) +3  keyword  "val"
  (3,8) +3  function [declaration]  "all"
  (3,14) +5  variable  "async"
  (3,20) +5  method  "allOf"
  (3,27) +1  variable  "t"
  (4,4) +3  keyword  "val"
  (4,8) +1  variable [declaration]  "a"
  (4,12) +4  keyword  "iter"
  (4,17) +4  keyword  "loop"
  (4,24) +5  keyword  "yield"
  (4,33) +5  keyword  "break"
  (5,4) +3  keyword  "val"
  (5,8) +1  variable [declaration]  "b"
  (5,12) +4  keyword  "iter"
  (5,17) +3  keyword  "for"
  (5,22) +5  keyword  "outer"
  (5,29) +2  parameter  "xs"
  (5,35) +1  variable  "x"
  (5,40) +2  keyword  "if"
  (5,44) +1  variable  "x"
  (5,53) +5  keyword  "break"
  (5,60) +5  keyword  "outer"
  (5,70) +5  keyword  "yield"
  (5,76) +1  variable  "x"
  (6,4) +3  keyword  "val"
  (6,8) +1  variable [declaration]  "c"
  (6,12) +6  keyword  "stream"
  (6,19) +5  keyword  "while"
  (6,26) +4  keyword  "true"
  (6,34) +5  keyword  "yield"
  (7,4) +3  keyword  "val"
  (7,8) +1  variable [declaration]  "d"
  (7,12) +6  keyword  "stream"
  (7,19) +3  keyword  "for"
  (7,23) +5  keyword  "await"
  (7,30) +1  variable  "s"
  (7,35) +1  variable  "x"
  (7,40) +5  keyword  "yield"
  (7,46) +1  variable  "x"
  (8,4) +3  keyword  "val"
  (8,8) +6  variable [declaration]  "stream"
  (9,4) +3  keyword  "val"
  (9,8) +4  variable [declaration]  "iter"
  (9,15) +1  parameter  "g"
  (9,17) +4  method  "iter"
  (10,4) +3  keyword  "val"
  (10,8) +4  variable [declaration]  "body"
  (10,15) +4  parameter  "http"
  (10,20) +6  method  "stream"
  (10,27) +6  variable  "stream"
  (11,4) +6  keyword  "return"
  (11,11) +5  keyword  "await"
  (11,17) +1  variable  "t"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 6 9 0
  0 8 5 7 0
  0 7 4 9 0
  1 0 2 9 0
  0 3 1 4 9
  0 2 2 6 0
  0 4 3 0 4
  0 7 1 6 0
  0 3 4 7 0
  0 6 4 6 0
  0 6 4 7 0
  0 9 5 0 4
  0 6 3 0 4
  1 4 3 9 0
  0 4 1 7 1
  0 4 5 9 0
  0 8 6 9 0
  1 4 3 9 0
  0 4 3 4 1
  0 6 5 7 0
  0 6 5 5 0
  0 7 1 7 0
  1 4 3 9 0
  0 4 1 7 1
  0 4 4 9 0
  0 5 4 9 0
  0 7 5 9 0
  0 9 5 9 0
  1 4 3 9 0
  0 4 1 7 1
  0 4 4 9 0
  0 5 3 9 0
  0 5 5 9 0
  0 7 2 6 0
  0 6 1 7 0
  0 5 2 9 0
  0 4 1 7 0
  0 9 5 9 0
  0 7 5 9 0
  0 10 5 9 0
  0 6 1 7 0
  1 4 3 9 0
  0 4 1 7 1
  0 4 6 9 0
  0 7 5 9 0
  0 7 4 9 0
  0 8 5 9 0
  1 4 3 9 0
  0 4 1 7 1
  0 4 6 9 0
  0 7 3 9 0
  0 4 5 9 0
  0 7 1 7 0
  0 5 1 7 0
  0 5 5 9 0
  0 6 1 7 0
  1 4 3 9 0
  0 4 6 7 1
  1 4 3 9 0
  0 4 4 7 1
  0 7 1 6 0
  0 2 4 5 0
  1 4 3 9 0
  0 4 4 7 1
  0 7 4 6 0
  0 5 6 5 0
  0 7 6 7 0
  1 4 6 9 0
  0 7 5 9 0
  0 6 1 7 0
