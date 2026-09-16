----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
val p = Point(x: 1, y: 2);
val xVal = @field(p, "x");
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
      "indent": "p",
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
      "indent": "xVal",
      "return_type": "Point",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Point"
          },
          {
            "value": "string"
          }
        ],
        "return_type": "Point"
      }
    }
  ]
}
```

