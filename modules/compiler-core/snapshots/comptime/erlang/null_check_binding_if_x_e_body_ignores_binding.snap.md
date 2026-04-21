----- SOURCE CODE -- main.bp
```botopink
fn check() -> string {
    var x = null;
    if (x) { e ->
        return "found";
    };
    return "none";
}
val r = check();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "check",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": [
        {
          "source": "var x = null;"
        },
        {
          "source": "if (x) { e ->"
        },
        {
          "source": "return \"none\";"
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

