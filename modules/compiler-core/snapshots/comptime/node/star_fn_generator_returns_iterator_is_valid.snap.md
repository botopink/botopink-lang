----- SOURCE CODE -- main.bp
```botopink
*fn gen() -> @Iterator<i32> {
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
      "return_type": "?",
      "body": [
        {
          "source": "yield 1;"
        }
      ]
    }
  ]
}
```

