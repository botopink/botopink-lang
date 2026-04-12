----- SOURCE CODE -- main.bp
```botopink
fn count() -> i32 {
    var n = 0;
    return n;
}
val r = count();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "count",
      "is_pub": false,
      "params": [],
      "return_type": "i32",
      "body": [
        {
          "source": "var n = 0;"
        },
        {
          "source": "return n;"
        }
      ]
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "i32"
      },
      "return_type": "i32"
    }
  ]
}
```

