----- SOURCE CODE -- main.bp
```botopink
val rf = RecordField(name: "x", typeName: "i32");
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "rf",
      "return_type": "RecordField",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "name",
            "value": "string"
          },
          {
            "name": "typeName",
            "value": "string"
          }
        ],
        "return_type": "RecordField"
      }
    }
  ]
}
```

