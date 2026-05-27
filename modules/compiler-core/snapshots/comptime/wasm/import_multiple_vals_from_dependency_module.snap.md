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
      "indent": "host",
      "return_type": "string"
    },
    {
      "ast": "val",
      "indent": "port",
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
      "indent": "addr",
      "return_type": "string"
    },
    {
      "ast": "val",
      "indent": "p",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "indent": "host",
          "return_type": "string"
        },
        {
          "ast": "use-declaration",
          "indent": "port",
          "return_type": "i32"
        }
      ]
    }
  ]
}
```

