----- SOURCE CODE -- main.bp
```botopink
pub fn html(expr template: string) -> string {
    return template;
}
val c = html @`
<p>hello</p>
`;
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub val c = "\n<p>hello</p>\n";
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
          "type": "__Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "__Expr<string>",
      "body": [
        {
          "source": "return template;"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "c",
      "return_type": "string"
    }
  ]
}
```

