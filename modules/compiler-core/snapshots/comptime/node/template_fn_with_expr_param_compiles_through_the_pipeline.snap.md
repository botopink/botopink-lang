----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
    return template;
}
val c = html """
<p>hello</p>
""";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "html",
      "is_pub": true,
      "params": [
        {
          "name": "template",
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "return template;"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "c",
      "return_type": "string"
    }
  ]
}
```

