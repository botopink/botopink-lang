----- SOURCE CODE -- main.bp
```botopink
pub fn greet(name: string) -> string {
    return "Hello, " + name;
}
val msg = greet("world");
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
          "type": ""
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
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "string"
          }
        ],
        "return_type": "string"
      },
      "return_type": "string"
    }
  ]
}
```

