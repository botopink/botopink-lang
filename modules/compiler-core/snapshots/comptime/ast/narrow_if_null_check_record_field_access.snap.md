----- SOURCE CODE -- main.bp
```botopink
type User(name: string)
fn greet(maybeUser: ?User) -> string {
    if (maybeUser) { u ->
        return "hello " + u.name;
    };
    return "no user";
}
fn main() {
    @print(greet(User(name: "alice")));
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
      "ast": "fn_def",
      "name": "greet",
      "is_pub": false,
      "params": [
        {
          "name": "maybeUser",
          "type": "?User"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (maybeUser) { u ->"
        },
        {
          "source": "return \"no user\";"
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
          "source": "@print(greet(User(name: \"alice\")));"
        }
      ]
    }
  ]
}
```

