----- SOURCE CODE -- main.bp
```botopink
val Box = type(value: i32);
val keys = @RecordKeys(Box);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Box",
      "id": 0,
      "fields": {
        "value": "i32"
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
            "value": "fn(i32) -> Box"
          }
        ],
        "return_type": "string[]"
      }
    }
  ]
}
```

