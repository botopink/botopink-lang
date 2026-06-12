----- SOURCE CODE -- main.bp
```botopink
record AppError { msg: string }
*fn fetch() -> @Result<i32, AppError> {
    throw AppError(msg: "fail");
}
fn process() -> i32 {
    val r = try fetch() catch 0;
    return r;
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
        "msg": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "fetch",
      "is_pub": false,
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "throw AppError(msg: \"fail\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "process",
      "is_pub": false,
      "params": [],
      "return_type": "i32",
      "body": [
        {
          "source": "val r = try fetch() catch 0;"
        },
        {
          "source": "return r;"
        }
      ]
    }
  ]
}
```

