----- SOURCE
```botopink
pub opaque type Token(v: i32) {
    pub fn of(v: i32) -> Token { return Token(v: v); }
}
val opaque = 1;
```

----- SEMANTIC TOKENS
  (0,0) +3  keyword  "pub"
  (0,4) +6  keyword  "opaque"
  (0,11) +4  keyword  "type"
  (0,16) +5  type [declaration]  "Token"
  (0,22) +1  property  "v"
  (0,25) +3  type [defaultLibrary]  "i32"
  (1,4) +3  keyword  "pub"
  (1,8) +2  keyword  "fn"
  (1,11) +2  method [declaration]  "of"
  (1,14) +1  parameter  "v"
  (1,17) +3  type [defaultLibrary]  "i32"
  (1,25) +5  type  "Token"
  (1,33) +6  keyword  "return"
  (1,40) +5  type  "Token"
  (1,46) +1  parameter  "v"
  (1,49) +1  parameter  "v"
  (3,0) +3  keyword  "val"
  (3,4) +6  variable [declaration]  "opaque"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 3 9 0
  0 4 6 9 0
  0 7 4 9 0
  0 5 5 0 1
  0 6 1 8 0
  0 3 3 0 4
  1 4 3 9 0
  0 4 2 9 0
  0 3 2 5 1
  0 3 1 6 0
  0 3 3 0 4
  0 8 5 0 0
  0 8 6 9 0
  0 7 5 0 0
  0 6 1 6 0
  0 3 1 6 0
  2 0 3 9 0
  0 4 6 7 1
