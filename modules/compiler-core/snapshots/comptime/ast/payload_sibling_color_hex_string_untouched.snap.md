----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 500 }
        Hex(value: string),
    }
}
fn red() -> Token { return .Color.Red.500; }
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
                  "name": "500"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "red",
      "is_pub": false,
      "params": [],
      "return_type": "Token",
      "body": [
        {
          "source": "fn red() -> Token { return .Color.Red.500; }"
        }
      ]
    }
  ]
}
```

