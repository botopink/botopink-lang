----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> @Task<i32> {
    return x;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "fetch",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": "i32"
        }
      ],
      "return_type": "Task<i32>",
      "body": [
        {
          "source": "return x;"
        }
      ]
    }
  ]
}
```

