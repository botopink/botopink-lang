----- SOURCE CODE -- main.bp
```botopink
#[@resultGenerator]
fn gen() -> @ResultGenerator<i32> {
    yield 1;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "gen",
      "is_pub": false,
      "params": [],
      "return_type": "ResultGenerator<i32,any>",
      "body": [
        {
          "source": "yield 1;"
        }
      ]
    }
  ]
}
```

