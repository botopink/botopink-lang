----- SOURCE CODE -- main.bp
```botopink
pub fn inner(comptime q: @Expr<string>) -> @Expr<string> {
    return q;
}
pub fn outer(comptime q: @Expr<string>) -> @Expr<string> {
    return q.build("inner(\"deep\")");
}
val s = outer "x";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "inner",
      "is_pub": true,
      "params": [
        {
          "name": "q",
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "return q;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "outer",
      "is_pub": true,
      "params": [
        {
          "name": "q",
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "return q.build(\"inner(\\\"deep\\\")\");"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "s",
      "return_type": "string"
    }
  ]
}
```

