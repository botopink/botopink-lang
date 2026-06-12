----- SOURCE CODE -- main.bp
```botopink
record AppError { code: i32, msg: string }
*fn load() -> @Result<string, AppError> {
    throw AppError(code: 500, msg: "boom");
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "AppError",
      "id": 0,
      "fields": {
        "code": "i32",
        "msg": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "load",
      "is_pub": false,
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "throw AppError(code: 500, msg: \"boom\");"
        }
      ]
    }
  ]
}
```

