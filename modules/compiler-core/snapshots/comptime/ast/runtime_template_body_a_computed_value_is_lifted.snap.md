----- SOURCE CODE -- main.bp
```botopink
pub fn six(syntax t: string) -> i32 {
    val n = 2 + 4;
    return n;
}
val n = six @`ignored`;
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub val n = 6;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "six",
      "is_pub": true,
      "params": [
        {
          "name": "t",
          "type": "__Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "__Expr<i32>",
      "body": [
        {
          "source": "val n = 2 + 4;"
        },
        {
          "source": "return n;"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "n",
      "return_type": "i32"
    }
  ]
}
```

