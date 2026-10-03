----- SOURCE CODE -- main.bp
```botopink
val info = @typeInfo(i32);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "info",
      "return_type": "TypeInfo<i32>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "TypeInfo<i32>"
      }
    }
  ]
}
```

