----- SOURCE CODE -- main.bp
```botopink
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") {
        throw "empty input";
    };
    return 0;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "parse",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "string"
        }
      ],
      "return_type": "Result<i32,string>",
      "body": [
        {
          "source": "if (s == \"\") {"
        },
        {
          "source": "return 0;"
        }
      ]
    }
  ]
}
```

