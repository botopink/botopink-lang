----- SOURCE
```botopink
pub type Users(name: string)
pub fn q(syntax e: string) -> anyvalue {
    val code = compiler.build("[1, 2]");
    val kw = CustomNode(kind: "kw", span: Span(0, 6, 1), label: "keyword", ref: null, children: []);
    val col = CustomNode(kind: "col", span: Span(7, 11, 1), label: "property", ref: compiler.lookup(e, "Users"), children: []);
    val root = CustomNode(kind: "root", span: Span(0, 0, 1), label: "none", ref: null, children: [kw, col]);
    compiler.custom(root);
    return code;
}
val xs = q @`select name from Users`;
import {compiler, compiler.Span, compiler.CustomNode} from "std";
```

----- SEMANTIC TOKENS
  (0,0) +3  keyword  "pub"
  (0,4) +4  keyword  "type"
  (0,9) +5  type [declaration]  "Users"
  (0,15) +4  property  "name"
  (0,21) +6  type [defaultLibrary]  "string"
  (1,0) +3  keyword  "pub"
  (1,4) +2  keyword  "fn"
  (1,7) +1  function [declaration]  "q"
  (1,9) +6  parameter  "syntax"
  (1,16) +1  variable  "e"
  (1,19) +6  type [defaultLibrary]  "string"
  (1,30) +8  type [defaultLibrary]  "anyvalue"
  (2,4) +3  keyword  "val"
  (2,8) +4  variable [declaration]  "code"
  (2,15) +8  variable  "compiler"
  (2,24) +5  method  "build"
  (3,4) +3  keyword  "val"
  (3,8) +2  variable [declaration]  "kw"
  (3,13) +10  type  "CustomNode"
  (3,24) +4  parameter  "kind"
  (3,36) +4  parameter  "span"
  (3,42) +4  type  "Span"
  (3,57) +5  parameter  "label"
  (3,75) +3  parameter  "ref"
  (3,80) +4  keyword  "null"
  (3,86) +8  parameter  "children"
  (4,4) +3  keyword  "val"
  (4,8) +3  variable [declaration]  "col"
  (4,14) +10  type  "CustomNode"
  (4,25) +4  parameter  "kind"
  (4,38) +4  parameter  "span"
  (4,44) +4  type  "Span"
  (4,60) +5  parameter  "label"
  (4,79) +3  parameter  "ref"
  (4,84) +8  variable  "compiler"
  (4,93) +6  method  "lookup"
  (4,100) +1  variable  "e"
  (4,113) +8  parameter  "children"
  (5,4) +3  keyword  "val"
  (5,8) +4  variable [declaration]  "root"
  (5,15) +10  type  "CustomNode"
  (5,26) +4  parameter  "kind"
  (5,40) +4  parameter  "span"
  (5,46) +4  type  "Span"
  (5,61) +5  parameter  "label"
  (5,76) +3  parameter  "ref"
  (5,81) +4  keyword  "null"
  (5,87) +8  parameter  "children"
  (5,98) +2  variable  "kw"
  (5,102) +3  variable  "col"
  (6,4) +8  variable  "compiler"
  (6,13) +6  method  "custom"
  (6,20) +4  variable  "root"
  (7,4) +6  keyword  "return"
  (7,11) +4  variable  "code"
  (9,0) +3  keyword  "val"
  (9,4) +2  variable [declaration]  "xs"
  (9,9) +1  function  "q"
  (9,13) +6  keyword  "select"
  (9,20) +4  property  "name"
  (10,0) +6  keyword  "import"
  (10,8) +8  variable  "compiler"
  (10,18) +8  variable  "compiler"
  (10,27) +4  property  "Span"
  (10,33) +8  variable  "compiler"
  (10,42) +10  property  "CustomNode"
  (10,54) +4  keyword  "from"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 3 9 0
  0 4 4 9 0
  0 5 5 0 1
  0 6 4 8 0
  0 6 6 0 4
  1 0 3 9 0
  0 4 2 9 0
  0 3 1 4 1
  0 2 6 6 0
  0 7 1 7 0
  0 3 6 0 4
  0 11 8 0 4
  1 4 3 9 0
  0 4 4 7 1
  0 7 8 7 0
  0 9 5 5 0
  1 4 3 9 0
  0 4 2 7 1
  0 5 10 0 0
  0 11 4 6 0
  0 12 4 6 0
  0 6 4 0 0
  0 15 5 6 0
  0 18 3 6 0
  0 5 4 9 0
  0 6 8 6 0
  1 4 3 9 0
  0 4 3 7 1
  0 6 10 0 0
  0 11 4 6 0
  0 13 4 6 0
  0 6 4 0 0
  0 16 5 6 0
  0 19 3 6 0
  0 5 8 7 0
  0 9 6 5 0
  0 7 1 7 0
  0 13 8 6 0
  1 4 3 9 0
  0 4 4 7 1
  0 7 10 0 0
  0 11 4 6 0
  0 14 4 6 0
  0 6 4 0 0
  0 15 5 6 0
  0 15 3 6 0
  0 5 4 9 0
  0 6 8 6 0
  0 11 2 7 0
  0 4 3 7 0
  1 4 8 7 0
  0 9 6 5 0
  0 7 4 7 0
  1 4 6 9 0
  0 7 4 7 0
  2 0 3 9 0
  0 4 2 7 1
  0 5 1 4 0
  0 4 6 9 0
  0 7 4 8 0
  1 0 6 9 0
  0 8 8 7 0
  0 10 8 7 0
  0 9 4 8 0
  0 6 8 7 0
  0 9 10 8 0
  0 12 4 9 0
