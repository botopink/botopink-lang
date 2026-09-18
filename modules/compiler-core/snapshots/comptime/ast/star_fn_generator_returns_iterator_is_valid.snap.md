----- SOURCE CODE -- main.bp
```botopink
#[@iterator]
fn gen() -> @Iterator<i32> {
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
      "return_type": "Iterator<i32,any,void>",
      "body": [
        {
          "source": "yield 1;"
        }
      ]
    }
  ]
}
```

