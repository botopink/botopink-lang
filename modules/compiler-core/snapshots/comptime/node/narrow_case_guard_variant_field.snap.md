----- SOURCE CODE -- main.bp
```botopink
type Response {
    Data(code: i32, body: string),
    Error(code: i32),
}
fn handle(r: Response) -> string {
    return case r {
        Data(code, body) if (code == 200) -> body;
        Data(code, body) if (code == 404) -> "not found";
        Data(code, body) -> "status " + code;
        Error(code) -> "error " + code;
    };
}
fn main() {
    @print(handle(Response.Data(200, "hi")));
    @print(handle(Response.Error(500)));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Response",
      "id": 0
    },
    {
      "ast": "fn_def",
      "name": "handle",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "Response"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case r {"
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
          "source": "@print(handle(Response.Data(200, \"hi\")));"
        },
        {
          "source": "@print(handle(Response.Error(500)));"
        }
      ]
    }
  ]
}
```

