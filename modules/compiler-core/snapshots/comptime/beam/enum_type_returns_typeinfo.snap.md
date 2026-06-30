----- SOURCE CODE -- main.bp
```botopink
val Color = enum { Red, Blue };
val info = @typeInfo(Color);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Color",
      "id": 0
    },
    {
      "ast": "val",
      "indent": "info",
      "return_type": "TypeInfo",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Color"
          }
        ],
        "return_type": "TypeInfo"
      }
    }
  ]
}
```

