----- SOURCE CODE -- main.bp
```botopink
val fields: RecordField[] = [RecordField(name: "a", typeName: "i32")];
val Rec = @makeRecord(fields);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "fields",
      "return_type": "RecordField[]"
    },
    {
      "ast": "val",
      "indent": "Rec",
      "return_type": "?",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "RecordField[]"
          }
        ],
        "return_type": "?"
      }
    }
  ]
}
```

