----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
val s = sign(1);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "sign",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": ""
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val r = if (n > 0) { \"positive\"; };"
        },
        {
          "source": "return r;"
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

