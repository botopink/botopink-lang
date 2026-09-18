----- SOURCE CODE -- main.bp
```botopink
fn increment() {
    var count = 0;
    count += 1;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "increment",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "var count = 0;"
        },
        {
          "source": "count += 1;"
        }
      ]
    }
  ]
}
```

