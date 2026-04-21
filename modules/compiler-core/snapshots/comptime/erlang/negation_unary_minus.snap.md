----- SOURCE CODE -- main.bp
```botopink
fn negate(x: i32) -> i32 {
    return -x;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "negate",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return -x;"
        }
      ]
    }
  ]
}
```

