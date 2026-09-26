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
      "variants": [
        {
          "name": "Hover",
          "fields": {
            "inner": "i32"
          }
        }
      ],
      "sections": [
        {
          "name": "Text",
          "variants": [
            {
              "name": "Bold"
            },
            {
              "name": "Italic"
            }
          ]
        }
      ]
    }
  ]
}
```

