----- SOURCE CODE -- main.bp
```botopink
pub type Button(
    label: string,
)
pub fn need(syntax t: string) -> string {
    val hit = compiler.lookup(t, "Buttom");
    if (hit) { b ->
        return compiler.fail("should be missing", at: t);
    };
    return compiler.build("\"ok\"");
}
val r = need @`<Buttom/>`;

import {compiler} from "std";
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
          "type": "__Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "__Expr<string>",
      "body": [
        {
          "source": "val hit = compiler.lookup(t, \"Buttom\");"
        },
        {
          "source": "if (hit) { b ->"
        },
        {
          "source": "return compiler.build(\"\\\"ok\\\"\");"
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

