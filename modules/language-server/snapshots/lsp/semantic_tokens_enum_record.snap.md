----- SOURCE
```botopink
val Color = enum { Red, Green, Blue };
val Point = record { x: i32, y: i32 };
```

----- SEMANTIC TOKENS
  (0,0) +3  keyword  "val"
  (0,4) +5  enum [declaration]  "Color"
  (0,12) +4  keyword  "enum"
  (0,19) +3  enumMember  "Red"
  (0,24) +5  enumMember  "Green"
  (0,31) +4  enumMember  "Blue"
  (1,0) +3  keyword  "val"
  (1,4) +5  type [declaration]  "Point"
  (1,12) +6  keyword  "record"
  (1,21) +1  variable  "x"
  (1,24) +3  type [defaultLibrary]  "i32"
  (1,29) +1  variable  "y"
  (1,32) +3  type [defaultLibrary]  "i32"
