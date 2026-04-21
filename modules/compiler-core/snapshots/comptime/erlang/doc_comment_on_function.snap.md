----- SOURCE CODE -- main.bp
```botopink
//// Adds two numbers
pub fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
val result = add(1, 2);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "add",
      "is_pub": true,
      "params": [
        {
          "name": "a",
          "type": ""
        },
        {
          "name": "b",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return a + b;"
        }
      ]
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          },
          {
            "value": "i32"
          }
        ],
        "return_type": "i32"
      },
      "return_type": "i32"
    }
  ]
}
```

