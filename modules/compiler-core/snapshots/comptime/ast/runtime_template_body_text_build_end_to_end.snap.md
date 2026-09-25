----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text();
    return q.build("\"" + t + "!\"");
}
val s = shout "hey";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val s = "hey!";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "shout",
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
          "source": "val t = q.text();"
        },
        {
          "source": "return q.build(\"\\\"\" + t + \"!\\\"\");"
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

