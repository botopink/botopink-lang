----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
val p = Point(x: 1, y: 2);
val PType = @TypeOf(p);
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
      "ast": "val",
      "ident": "PType",
      "return_type": "Point",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Point"
          }
        ],
        "return_type": "Point"
      }
    }
  ]
}
```

