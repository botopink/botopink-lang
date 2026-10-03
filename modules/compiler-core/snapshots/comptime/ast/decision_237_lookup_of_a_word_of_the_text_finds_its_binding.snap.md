----- SOURCE CODE -- main.bp
```botopink
pub type Card(
    title: string,
)
pub type Badge(
    n: i32,
)
val unrelated = 1;
pub fn ui(comptime q: @Expr<string>) -> @Expr<string> {
    val count = q.bindings().length;
    val hit = q.lookup("Badge");
    if (hit) { b ->
        return q.build("\"" + b.name + "/" + b.local + "\"");
    } else {
        return q.fail("Badge is a word of the text and in scope");
    };
}
val s = ui "<Card title=\"x\"><Badge/></Card>";
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

pub val s = "Badge/Badge";
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
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "Expr<string>",
      "body": [
        {
          "source": "val count = q.bindings().length;"
        },
        {
          "source": "val hit = q.lookup(\"Badge\");"
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

