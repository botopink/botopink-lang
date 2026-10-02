----- SOURCE CODE -- shapes.bp
```botopink
pub type Item(id: i32)
```

----- TYPED AST JSON -- shapes.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Item",
      "fields": {
        "id": "i32"
      }
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {Item} from "shapes";
pub fn dsl<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
    val code = e.build("41");
    val leaf = CustomNode(kind: "field", span: Span(7, 9, 1), label: "property", ref: e.lookup("Item"), children: []);
    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
    return e.custom(root, code);
}
val rows = dsl "select id";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
import {Item} from "shapes";

pub val rows = 41;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "dsl",
      "is_pub": true,
      "generic_params": [
        "T"
      ],
      "params": [
        {
          "name": "e",
          "type": "Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "CustomExpr<'a>",
      "body": [
        {
          "source": "val code = e.build(\"41\");"
        },
        {
          "source": "val leaf = CustomNode(kind: \"field\", span: Span(7, 9, 1), label: \"property\", ref: e.lookup(\"Item\"), children: []);"
        },
        {
          "source": "val root = CustomNode(kind: \"select\", span: Span(0, 6, 1), label: \"keyword\", ref: null, children: [leaf]);"
        },
        {
          "source": "return e.custom(root, code);"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "rows",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "Item",
          "return_type": "fn(i32) -> Item"
        }
      ]
    }
  ]
}
```

