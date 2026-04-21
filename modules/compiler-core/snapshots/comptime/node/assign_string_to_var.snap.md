----- SOURCE CODE -- main.bp
```botopink
fn f() {
    var name = "old";
    name = "new";
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
          "source": "var name = \"old\";"
        },
        {
          "source": "name = \"new\";"
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

