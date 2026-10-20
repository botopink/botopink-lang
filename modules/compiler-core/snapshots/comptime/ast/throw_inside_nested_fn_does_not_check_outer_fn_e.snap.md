----- SOURCE CODE -- main.bp
```botopink
fn outer() -> Result<i32, string> {
    val cb: fn() -> Result<void, i32> = fn() -> Result<void, i32> {
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
      "return_type": "Result<i32,string>",
      "body": [
        {
          "source": "val cb: fn() -> Result<void, i32> = fn() -> Result<void, i32> {"
        },
        {
          "source": "throw \"outer error\";"
        }
      ]
    }
  ]
}
```

