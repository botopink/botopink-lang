----- SOURCE CODE -- main.bp
```botopink
val Point = type(x: i32, y: string);
val keys = @RecordKeys(Point);
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
        "y": "string"
      }
    },
    {
      "ast": "val",
      "indent": "keys",
      "return_type": "string[]",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "fn(i32, string) -> Point"
          }
        ],
        "return_type": "string[]"
      }
    }
  ]
}
```

