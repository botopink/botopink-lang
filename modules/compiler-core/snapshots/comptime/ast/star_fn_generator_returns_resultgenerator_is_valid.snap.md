----- SOURCE CODE -- main.bp
```botopink
iter fn gen() -> Iter<i32> {
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
      "return_type": "Iter<i32>",
      "body": [
        {
          "source": "yield 1;"
        }
      ]
    }
  ]
}
```

