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
  (1,21) +1  property  "x"
  (1,24) +3  type [defaultLibrary]  "i32"
  (1,29) +1  property  "y"
  (1,32) +3  type [defaultLibrary]  "i32"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 3 9 0
  0 4 5 2 1
  0 8 4 9 0
  0 7 3 3 0
  0 5 5 3 0
  0 7 4 3 0
  1 0 3 9 0
  0 4 5 0 1
  0 8 6 9 0
  0 9 1 8 0
  0 3 3 0 4
  0 5 1 8 0
  0 3 3 0 4
