----- SOURCE CODE -- main.bp
```botopink
pub fn inner(syntax q: string) -> string {
    return q;
}
pub fn outer(syntax q: string) -> string {
    return compiler.build("inner @`deep`");
}
val s = outer @`x`;

import {compiler} from "std";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub val s = "deep";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "inner",
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
          "source": "return q;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "outer",
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
          "source": "return compiler.build(\"inner @`deep`\");"
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

