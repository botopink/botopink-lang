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

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val s = inner();
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
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
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
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
      "body": [
        {
          "source": "return q.build(\"inner(\\\"deep\\\")\");"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "s",
      "return_type": "string"
    }
  ]
}
```

