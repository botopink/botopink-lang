----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
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
          "source": "val answer = 42;"
        },
        {
          "source": "val assert 42 = answer catch throw \"not 42\";"
        }
      ]
    }
  ]
}
```

