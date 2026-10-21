----- SOURCE CODE -- main.bp
```botopink
pub fn shout(syntax q: string) -> string {
    val t = compiler.text(q);
    return compiler.build("\"" + t + "!\"");
}
val s = shout @`hey`;

import {compiler} from "std";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub val s = "hey!";
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
          "type": "__Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "__Expr<string>",
      "body": [
        {
          "source": "val t = compiler.text(q);"
        },
        {
          "source": "return compiler.build(\"\\\"\" + t + \"!\\\"\");"
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

