----- SOURCE CODE -- main.bp
```botopink
pub fn compute(x: i32) -> i32 {
    val doubled = x + x;
    return doubled;
}
val result = compute(21);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "compute",
      "is_pub": true,
      "params": [
        {
          "name": "x",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "val doubled = x + x;"
        },
        {
          "source": "return doubled;"
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
          }
        ],
        "return_type": "i32"
      },
      "return_type": "i32"
    }
  ]
}
```

