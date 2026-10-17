----- SOURCE CODE -- main.bp
```botopink
val cfg_1 = "unread";
pub fn conf(expr q: string) -> i32 {
    val n = compiler.bindings(q).length;
    return n;
}
val n = conf @`cfg-0`;
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub val cfg_1 = "unread";

pub val n = 0;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "cfg_1",
      "return_type": "string"
    },
    {
      "ast": "fn_def",
      "name": "conf",
      "is_pub": true,
      "params": [
        {
          "name": "q",
          "type": "__Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "__Expr<i32>",
      "body": [
        {
          "source": "val n = compiler.bindings(q).length;"
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

