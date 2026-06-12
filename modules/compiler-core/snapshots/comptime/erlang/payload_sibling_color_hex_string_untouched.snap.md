----- SOURCE CODE -- main.bp
```botopink
enum Token {
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
      "id": 0
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

