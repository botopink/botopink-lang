----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert 42 = answer catch throw Error("not 42");
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
          "source": "val assert 42 = answer catch throw Error(\"not 42\");"
        }
      ]
    }
  ]
}
```

