----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "\"\"";
    for (q.parts()) { p ->
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

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val name = "world";

val page = "" + "<p>" + name + "</p>";
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
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
      "body": [
        {
          "source": "var acc = \"\\\"\\\"\";"
        },
        {
          "source": "for (q.parts()) { p ->"
        },
        {
          "source": "return q.build(acc);"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "name",
      "return_type": "string"
    },
    {
      "ast": "val",
      "ident": "page",
      "return_type": "string"
    }
  ]
}
```

