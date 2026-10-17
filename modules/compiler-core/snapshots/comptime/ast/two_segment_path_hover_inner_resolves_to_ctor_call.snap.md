----- SOURCE CODE -- main.bp
```botopink
type Token {
    Text {
        Bold, Italic,
    }
    Hover(inner: i32),
}
fn pick() -> Token {
    return .Text.Bold;
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
    },
    {
      "ast": "fn_def",
      "name": "pick",
      "is_pub": false,
      "params": [],
      "return_type": "Token",
      "body": [
        {
          "source": "return .Text.Bold;"
        }
      ]
    }
  ]
}
```

