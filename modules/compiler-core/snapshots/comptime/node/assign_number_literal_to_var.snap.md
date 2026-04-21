----- SOURCE CODE -- main.bp
```botopink
fn f() {
    var x = 0;
    x = 10;
}
val r = f();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "f",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "var x = 0;"
        },
        {
          "source": "x = 10;"
        }
      ]
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "void"
      },
      "return_type": "void"
    }
  ]
}
```

