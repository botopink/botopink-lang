----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) { "positive"; } else { "non-positive"; };
}
val s = describe(5);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "describe",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "i32"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return if (n > 0) { \"positive\"; } else { \"non-positive\"; };"
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
        "return_type": "string"
      },
      "return_type": "string"
    }
  ]
}
```

