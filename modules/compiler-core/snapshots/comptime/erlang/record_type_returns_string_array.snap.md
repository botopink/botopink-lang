----- SOURCE CODE -- main.bp
```botopink
val Point = record { x: i32, y: string };
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
      "return_type": "Array<string>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Point"
          }
        ],
        "return_type": "Array<string>"
      }
    }
  ]
}
```

