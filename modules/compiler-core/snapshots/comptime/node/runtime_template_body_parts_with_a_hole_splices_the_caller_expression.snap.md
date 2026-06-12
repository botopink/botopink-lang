----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "\"\"";
    loop (q.parts()) { p ->
        if (p.kind == "Text") {
            acc = acc + " + \"" + p.text + "\"";
        };
        if (p.kind == "Interp") {
            acc = acc + " + " + p.code;
        };
    };
    return q.build(acc);
}
val name = "world";
val page = html """<p>${name}</p>""";
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
          "name": "q",
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "var acc = \"\\\"\\\"\";"
        },
        {
          "source": "loop (q.parts()) { p ->"
        },
        {
          "source": "return q.build(acc);"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "name",
      "return_type": "string"
    },
    {
      "ast": "val",
      "indent": "page",
      "return_type": "string"
    }
  ]
}
```

