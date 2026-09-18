----- SOURCE CODE -- main.bp
```botopink
val info = @typeInfo(f64);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "info",
      "return_type": "TypeInfo",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "f64"
          }
        ],
        "return_type": "TypeInfo"
      }
    }
  ]
}
```

