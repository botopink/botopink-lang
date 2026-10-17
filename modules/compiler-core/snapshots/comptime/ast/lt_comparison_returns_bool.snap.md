----- SOURCE CODE -- main.bp
```botopink
val less = 1 < 2;
val bigger = 10 < 5;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "less",
      "return_type": "bool"
    },
    {
      "ast": "val",
      "ident": "bigger",
      "return_type": "bool"
    }
  ]
}
```

