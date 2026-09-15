----- SOURCE CODE -- main.bp
```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    val t = q.text();
    return q.build("\"" + t + "!\"");
}
val s = shout "hey";
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
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
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
      "indent": "s",
      "return_type": "string"
    }
  ]
}
```

