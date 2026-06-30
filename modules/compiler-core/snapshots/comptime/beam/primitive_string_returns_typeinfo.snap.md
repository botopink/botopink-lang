----- SOURCE CODE -- main.bp
```botopink
val info = @typeInfo(string);
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
            "value": "string"
          }
        ],
        "return_type": "TypeInfo"
      }
    }
  ]
}
```

