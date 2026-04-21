----- SOURCE CODE -- base.bp
```botopink
pub val VERSION = 1;
```

----- TYPED AST JSON -- base.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "return_type": "i32"
    }
  ]
}
```


----- SOURCE CODE -- mid.bp
```botopink
use {VERSION} from "base";
pub val MAJOR = VERSION;
```

----- TYPED AST JSON -- mid.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "return_type": "i32"
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
use {MAJOR} from "mid";
val v = MAJOR;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "return_type": "i32"
    }
  ]
}
```

