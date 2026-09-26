----- SOURCE CODE -- config.bp
```botopink
pub val host = "localhost";
pub val port = 8080;
```

----- TYPED AST JSON -- config.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "host",
      "return_type": "string"
    },
    {
      "ast": "val",
      "ident": "port",
      "return_type": "i32"
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {host, port} from "config";
val addr = host;
val p = port;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "addr",
      "return_type": "string"
    },
    {
      "ast": "val",
      "ident": "p",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "host",
          "return_type": "string"
        },
        {
          "ast": "use-declaration",
          "ident": "port",
          "return_type": "i32"
        }
      ]
    }
  ]
}
```

