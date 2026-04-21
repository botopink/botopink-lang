----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> i32 {
    @todo();
}
fn safe() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
val x = safe();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "fetch",
      "is_pub": false,
      "params": [],
      "return_type": "i32",
      "body": [
        {
          "source": "@todo();"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "safe",
      "is_pub": false,
      "params": [],
      "return_type": "i32",
      "body": [
        {
          "source": "val r = try fetch() catch 0;"
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
        "params": [],
        "return_type": "i32"
      },
      "return_type": "i32"
    }
  ]
}
```

