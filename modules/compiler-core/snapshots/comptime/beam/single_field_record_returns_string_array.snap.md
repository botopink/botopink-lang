----- SOURCE CODE -- main.bp
```botopink
val Box = record { value: i32 };
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
      "return_type": "Array<string>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Box"
          }
        ],
        "return_type": "Array<string>"
      }
    }
  ]
}
```

