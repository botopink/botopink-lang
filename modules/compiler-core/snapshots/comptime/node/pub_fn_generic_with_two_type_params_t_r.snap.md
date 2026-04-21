----- SOURCE CODE -- main.bp
```botopink
pub fn transform<T, R>(x: T, y: R) -> R {
    return y;
}
val result = transform(42, "mapped");
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "transform",
      "is_pub": true,
      "generic_params": [
        "T",
        "R"
      ],
      "params": [
        {
          "name": "x",
          "type": ""
        },
        {
          "name": "y",
          "type": ""
        }
      ],
      "return_type": "R",
      "body": [
        {
          "source": "return y;"
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

