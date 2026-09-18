----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse() -> @Result<i32, string> {
    return 42;
}
fn f() {
    val result = parse();
    val assert Ok(value) = result catch throw "not ok";
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "parse",
      "is_pub": false,
      "params": [],
      "return_type": "?",
      "body": [
        {
          "source": "return 42;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "f",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val result = parse();"
        },
        {
          "source": "val assert Ok(value) = result catch throw \"not ok\";"
        }
      ]
    }
  ]
}
```

