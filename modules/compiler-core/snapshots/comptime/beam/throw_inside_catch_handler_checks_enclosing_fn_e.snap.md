----- SOURCE CODE -- main.bp
```botopink
*fn fetch() -> @Result<i32, string> {
    throw "primary";
}
*fn process() -> @Result<i32, string> {
    val r = try fetch() catch throw "secondary";
    return r;
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
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "throw \"primary\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "process",
      "is_pub": false,
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "val r = try fetch() catch throw \"secondary\";"
        },
        {
          "source": "return r;"
        }
      ]
    }
  ]
}
```

