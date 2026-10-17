----- SOURCE CODE -- main.bp
```botopink
fn identity(x: i32) -> i32 { return x; }
val FnType = @TypeOf(identity);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "identity",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn identity(x: i32) -> i32 { return x; }"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "FnType",
      "return_type": "fn(i32) -> i32",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "fn(i32) -> i32"
          }
        ],
        "return_type": "fn(i32) -> i32"
      }
    }
  ]
}
```

