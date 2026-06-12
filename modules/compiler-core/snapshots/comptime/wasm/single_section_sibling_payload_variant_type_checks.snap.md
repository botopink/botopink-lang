----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Text {
        Bold,
        Italic,
    }
    Hover(inner: i32),
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

