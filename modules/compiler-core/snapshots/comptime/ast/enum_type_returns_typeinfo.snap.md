----- SOURCE CODE -- main.bp
```botopink
val Color = type { Red, Blue };
val info = @typeInfo(Color);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Color",
      "variants": [
        {
          "name": "Red"
        },
        {
          "name": "Blue"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "info",
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

