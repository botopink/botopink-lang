----- SOURCE CODE -- main.bp
```botopink
val ti: TypeInfo<i32> = @typeInfo(i32);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "ti",
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

