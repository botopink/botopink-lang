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
      "return_type": "string"
    },
    {
      "ast": "val",
      "return_type": "i32"
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
use {host, port} from "config";
val addr = host;
val p = port;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "return_type": "string"
    },
    {
      "ast": "val",
      "return_type": "i32"
    }
  ]
}
```

