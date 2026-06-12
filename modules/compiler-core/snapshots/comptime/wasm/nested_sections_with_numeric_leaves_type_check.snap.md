----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Color {
        Red { 100, 500 }
        Hex(value: string),
    }
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Token",
      "id": 0
    }
  ]
}
```

