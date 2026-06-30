----- SOURCE CODE -- main.bp
```botopink
val info = @typeInfo(bool);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "info",
      "return_type": "TypeInfo",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "bool"
          }
        ],
        "return_type": "TypeInfo"
      }
    }
  ]
}
```

