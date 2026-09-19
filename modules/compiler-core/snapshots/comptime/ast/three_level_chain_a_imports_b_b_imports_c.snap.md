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
      "ident": "VERSION",
      "return_type": "i32"
    }
  ]
}
```


----- SOURCE CODE -- mid.bp
```botopink
import {VERSION} from "base";
pub val MAJOR = VERSION;
```

----- TYPED AST JSON -- mid.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "MAJOR",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "VERSION",
          "return_type": "i32"
        }
      ]
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {MAJOR} from "mid";
val v = MAJOR;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "v",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "MAJOR",
          "return_type": "i32"
        }
      ]
    }
  ]
}
```

