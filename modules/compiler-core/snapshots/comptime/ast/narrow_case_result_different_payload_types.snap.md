----- SOURCE CODE -- main.bp
```botopink
type User(name: string)
type AppError { NotFound, Timeout(msg: string) }
fn fetchUser(id: i32) -> @Result<User, AppError> {
    if (id == 0) { throw AppError.NotFound; };
    return User(name: "alice");
}
fn main() {
    val r = fetchUser(1);
    case r {
        Ok(u) -> @print(u.name);
        Err(e) -> @print(case e {
            NotFound -> "404";
            Timeout(msg) -> "timeout: " + msg;
        });
    };
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "User",
      "fields": {
        "name": "string"
      }
    },
    {
      "ast": "enum_def",
      "name": "AppError",
      "variants": [
        {
          "name": "NotFound"
        },
        {
          "name": "Timeout",
          "fields": {
            "msg": "string"
          }
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "fetchUser",
      "is_pub": false,
      "params": [
        {
          "name": "id",
          "type": "i32"
        }
      ],
      "return_type": "Result<User,AppError>",
      "body": [
        {
          "source": "if (id == 0) { throw AppError.NotFound; };"
        },
        {
          "source": "return User(name: \"alice\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val r = fetchUser(1);"
        },
        {
          "source": "case r {"
        }
      ]
    }
  ]
}
```

