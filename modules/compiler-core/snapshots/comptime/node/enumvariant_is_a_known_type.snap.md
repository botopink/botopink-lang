----- SOURCE CODE -- main.bp
```botopink
val ev = EnumVariant(name: "Red", fields: []);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "ev",
      "return_type": "EnumVariant",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "name",
            "value": "string"
          },
          {
            "name": "fields",
            "value": "RecordField[]"
          }
        ],
        "return_type": "EnumVariant"
      }
    }
  ]
}
```

