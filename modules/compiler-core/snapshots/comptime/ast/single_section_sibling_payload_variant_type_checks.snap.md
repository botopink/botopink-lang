----- SOURCE CODE -- main.bp
```botopink
type Token {
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

