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
      "ident": "fields",
      "return_type": "RecordField[]"
    },
    {
      "ast": "val",
      "ident": "Rec",
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

