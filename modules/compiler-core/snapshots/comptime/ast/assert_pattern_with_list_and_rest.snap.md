----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "f",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val items = [1, 2, 3, 4];"
        },
        {
          "source": "val assert [first, second, ..rest] = items catch [];"
        }
      ]
    }
  ]
}
```

