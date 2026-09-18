----- SOURCE CODE -- main.bp
```botopink
type Token {
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
      "sections": [
        {
          "name": "Color",
          "variants": [
            {
              "name": "Hex",
              "fields": {
                "value": "string"
              }
            }
          ],
          "sections": [
            {
              "name": "Red",
              "variants": [
                {
                  "name": "100"
                },
                {
                  "name": "500"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

