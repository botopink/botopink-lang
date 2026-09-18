----- SOURCE CODE -- main.bp
```botopink
fn greet() -> string {
    var msg = "hello";
    return msg;
}
val r = greet();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "greet",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": [
        {
          "source": "var msg = \"hello\";"
        },
        {
          "source": "return msg;"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "r",
      "return_type": "string",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "string"
      }
    }
  ]
}
```

