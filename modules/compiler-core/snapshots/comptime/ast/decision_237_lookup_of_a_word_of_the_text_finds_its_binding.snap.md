----- SOURCE CODE -- main.bp
```botopink
pub type Card(
    title: string,
)
pub type Badge(
    n: i32,
)
val unrelated = 1;
pub fn ui(syntax q: string) -> string {
    val count = compiler.bindings(q).length;
    val hit = compiler.lookup(q, "Badge");
    if (hit) { b ->
        return compiler.build("\"" + b.name + "/" + b.module + "\"");
    } else {
        return compiler.fail("Badge is a word of the text and in scope", at: q);
    };
}
val s = ui @`<Card title="x"><Badge/></Card>`;

import {compiler} from "std";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
pub type Card(
    title: string,
)

pub type Badge(
    n: i32,
)

pub val unrelated = 1;

pub val s = "Badge/";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Card",
      "fields": {
        "title": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "Badge",
      "fields": {
        "n": "i32"
      }
    },
    {
      "ast": "val",
      "ident": "unrelated",
      "return_type": "i32"
    },
    {
      "ast": "fn_def",
      "name": "ui",
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
          "source": "val count = compiler.bindings(q).length;"
        },
        {
          "source": "val hit = compiler.lookup(q, \"Badge\");"
        },
        {
          "source": "if (hit) { b ->"
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

