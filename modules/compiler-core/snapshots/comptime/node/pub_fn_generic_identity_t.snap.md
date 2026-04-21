----- SOURCE CODE -- main.bp
```botopink
pub fn identity<T>(x: T) -> T {
    return x;
}
val r = identity(42);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "identity",
      "is_pub": true,
      "generic_params": [
        "T"
      ],
      "params": [
        {
          "name": "x",
          "type": ""
        }
      ],
      "return_type": "T",
      "body": [
        {
          "source": "return x;"
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

