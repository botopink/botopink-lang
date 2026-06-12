----- SOURCE CODE -- main.bp
```botopink
pub fn six(comptime t: @Expr<string>) -> @Expr<i32> {
    val n = 2 + 4;
    return @expr(n);
}
val n = six "ignored";
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
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "val n = 2 + 4;"
        },
        {
          "source": "return @expr(n);"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "n",
      "return_type": "i32"
    }
  ]
}
```

