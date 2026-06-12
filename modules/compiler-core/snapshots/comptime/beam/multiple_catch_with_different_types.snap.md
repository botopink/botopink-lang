----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
*fn getName() -> @Result<string, UserError> {
    throw UserError(msg: "missing");
}
*fn getAge() -> @Result<i32, UserError> {
    throw UserError(msg: "missing");
}
fn loadUser() {
    val name = try getName() catch "anon";
    val age = try getAge() catch 0;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "UserError",
      "id": 0,
      "fields": {
        "msg": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "getName",
      "is_pub": false,
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "throw UserError(msg: \"missing\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "getAge",
      "is_pub": false,
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "throw UserError(msg: \"missing\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "loadUser",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val name = try getName() catch \"anon\";"
        },
        {
          "source": "val age = try getAge() catch 0;"
        }
      ]
    }
  ]
}
```

