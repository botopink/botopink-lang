----- SOURCE CODE -- main.bp
```botopink
pub type Button(
    label: string,
)
pub fn need(comptime t: @Expr<string>) -> @Expr<string> {
    val hit = t.lookup("Buttom");
    if (hit) { b ->
        return t.fail("should be missing");
    };
    return t.build("\"ok\"");
}
val r = need "x";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub type Button(
    label: string,
)

pub val r = "ok";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Button",
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
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
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
      "ident": "r",
      "return_type": "string"
    }
  ]
}
```

