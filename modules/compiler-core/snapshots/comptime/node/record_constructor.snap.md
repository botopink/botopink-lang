----- SOURCE CODE -- main.bp
```botopink
val Point = record { x: i32, y: i32 };
val p = Point(x: 1, y: 2);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Point",
      "id": 0,
      "fields": {
        "x": "i32",
        "y": "i32"
      }
    },
    {
      "ast": "val",
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
      },
      "return_type": "Point"
    }
  ]
}
```

