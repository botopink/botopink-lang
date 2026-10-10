----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
    }
}
type Border {
    Color {
        Red { 100, 500 }
    }
}
val a = Token.Color.Red.500;
val b = Border.Color.Red.500;
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
            }
          ]
        }
      ]
    },
    {
      "ast": "enum_def",
      "name": "Border",
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
            }
          ]
        }
      ]
    },
    {
      "ast": "val",
      "ident": "a",
      "return_type": "Token",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "_inner",
            "value": "__Token__Color"
          }
        ],
        "return_type": "Token"
      }
    },
    {
      "ast": "val",
      "ident": "b",
      "return_type": "Border",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "_inner",
            "value": "__Border__Color"
          }
        ],
        "return_type": "Border"
      }
    }
  ]
}
```

