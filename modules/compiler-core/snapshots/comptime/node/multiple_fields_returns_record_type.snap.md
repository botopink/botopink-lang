----- SOURCE CODE -- main.bp
```botopink
val fields: RecordField[] = [
    RecordField(name: "x", typeName: "i32"),
    RecordField(name: "y", typeName: "i32"),
];
val Point = @makeRecord(fields);
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
      "indent": "Point",
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

