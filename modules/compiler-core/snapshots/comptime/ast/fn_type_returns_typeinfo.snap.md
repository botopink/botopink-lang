----- SOURCE CODE -- main.bp
```botopink
fn add(a: i32, b: i32) -> i32 { return a + b; }
val info = @typeInfo(add);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "add",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": "i32"
        },
        {
          "name": "b",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "fn add(a: i32, b: i32) -> i32 { return a + b; }"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "info",
      "return_type": "TypeInfo",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "TypeInfo"
      }
    }
  ]
}
```

