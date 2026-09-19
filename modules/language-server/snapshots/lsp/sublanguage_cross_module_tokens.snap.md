----- SOURCE
```botopink
import { erika, Cities } from "erika";
val xs = erika "select name";
```

----- SEMANTIC TOKENS
  (0,0) +6  keyword  "import"
  (0,9) +5  function  "erika"
  (0,16) +6  type  "Cities"
  (0,25) +4  keyword  "from"
  (1,0) +3  keyword  "val"
  (1,4) +2  variable [declaration]  "xs"
  (1,9) +5  function  "erika"
  (1,16) +6  keyword  "select"
  (1,23) +4  property  "name"
----- ENCODED (deltaLine, deltaStart, len, type, mods)
  0 0 6 9 0
  0 9 5 4 0
  0 7 6 0 0
  0 9 4 9 0
  1 0 3 9 0
  0 4 2 7 1
  0 5 5 4 0
  0 7 6 9 0
  0 7 4 8 0
