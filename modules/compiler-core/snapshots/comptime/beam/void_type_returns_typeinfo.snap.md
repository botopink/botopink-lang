----- SOURCE CODE -- main.bp
```botopink
val info = @typeInfo(void);
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
            "value": "void"
          }
        ],
        "return_type": "TypeInfo"
      }
    }
  ]
}
```

