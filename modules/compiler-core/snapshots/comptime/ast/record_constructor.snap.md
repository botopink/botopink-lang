----- SOURCE CODE -- main.bp
```botopink
val Point = type(x: i32, y: i32);
val p = Point(x: 1, y: 2);
fn main() {
    @print(p);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Point",
      "fields": {
        "x": "i32",
        "y": "i32"
      }
    },
    {
      "ast": "val",
      "ident": "p",
      "return_type": "Point",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "x",
            "value": "i32"
          },
          {
            "name": "y",
            "value": "i32"
          }
        ],
        "return_type": "Point"
      }
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(p);"
        }
      ]
    }
  ]
}
```

