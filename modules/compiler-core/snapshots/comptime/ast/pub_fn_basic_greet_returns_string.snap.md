----- SOURCE CODE -- main.bp
```botopink
pub fn greet(name: string) -> string {
    return "Hello, " + name;
}
val msg = greet("world");
fn main() {
    @print(msg);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "greet",
      "is_pub": true,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return \"Hello, \" + name;"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "msg",
      "return_type": "string",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "string"
          }
        ],
        "return_type": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(msg);"
        }
      ]
    }
  ]
}
```

