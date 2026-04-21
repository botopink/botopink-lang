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
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "string"
      },
      "return_type": "string"
    }
  ]
}
```

