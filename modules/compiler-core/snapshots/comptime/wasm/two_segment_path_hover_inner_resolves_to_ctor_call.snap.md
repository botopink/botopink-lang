----- SOURCE CODE -- main.bp
```botopink
enum Token {
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
      "id": 0
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

