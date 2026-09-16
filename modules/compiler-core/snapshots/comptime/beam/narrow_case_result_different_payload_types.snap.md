----- SOURCE CODE -- main.bp
```botopink
record User { name: string }
enum AppError { NotFound, Timeout(msg: string) }
#[@result]
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
      "id": 0,
      "fields": {
        "name": "string"
      }
    },
    {
      "ast": "enum_def",
      "name": "AppError",
      "id": 0
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
      "return_type": "?",
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

