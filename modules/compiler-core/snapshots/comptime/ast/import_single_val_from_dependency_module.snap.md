----- SOURCE CODE -- constants.bp
```botopink
pub val MAX = 100;
```

----- TYPED AST JSON -- constants.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "MAX",
      "return_type": "i32"
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {MAX} from "constants";
val limit = MAX;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "limit",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "MAX",
          "return_type": "i32"
        }
      ]
    }
  ]
}
```

