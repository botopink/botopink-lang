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
      "return_type": "bool"
    },
    {
      "ast": "val",
      "return_type": "bool"
    }
  ]
}
```

