----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn validate(n: i32) -> @Result<i32, string> {
    if (n < 0) {
        throw "negative";
    };
    if (n > 100) {
        throw "too big";
    };
    return n;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "validate",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "i32"
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "if (n < 0) {"
        },
        {
          "source": "if (n > 100) {"
        },
        {
          "source": "return n;"
        }
      ]
    }
  ]
}
```

