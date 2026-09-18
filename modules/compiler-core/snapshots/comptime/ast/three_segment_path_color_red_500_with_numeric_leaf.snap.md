----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
        Blue { 100, 500 }
    }
}
fn red() -> Token {
    return .Color.Red.500;
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
            },
            {
              "name": "Blue",
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
    },
    {
      "ast": "fn_def",
      "name": "red",
      "is_pub": false,
      "params": [],
      "return_type": "Token",
      "body": [
        {
          "source": "return .Color.Red.500;"
        }
      ]
    }
  ]
}
```

