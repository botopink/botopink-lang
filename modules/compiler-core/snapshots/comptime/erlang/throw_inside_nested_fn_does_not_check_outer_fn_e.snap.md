----- SOURCE CODE -- main.bp
```botopink
*fn outer() -> @Result<i32, string> {
    val cb = fn() {
        throw 404;
    };
    throw "outer error";
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "outer",
      "is_pub": false,
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "val cb = fn() {"
        },
        {
          "source": "throw \"outer error\";"
        }
      ]
    }
  ]
}
```

