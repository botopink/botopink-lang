----- SOURCE CODE -- main.bp
```botopink
pub struct Button {
    label: string,
}
pub fn need(comptime t: @Expr<string>) -> @Expr<string> {
    val hit = t.lookup("Buttom");
    if (hit) { b ->
        return t.fail("should be missing");
    };
    return t.build("\"ok\"");
}
val r = need "x";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "struct_def",
      "name": "Button",
      "id": 0,
      "fields": {
        "label": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "need",
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
          "source": "val hit = t.lookup(\"Buttom\");"
        },
        {
          "source": "if (hit) { b ->"
        },
        {
          "source": "return t.build(\"\\\"ok\\\"\");"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "r",
      "return_type": "string"
    }
  ]
}
```

