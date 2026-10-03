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
      "ident": "fields",
      "return_type": "RecordField[]"
    },
    {
      "ast": "val",
      "ident": "Point",
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

