----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert "hello" = greeting catch throw Error("not hello");
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
          "source": "val assert \"hello\" = greeting catch throw Error(\"not hello\");"
        }
      ]
    }
  ]
}
```

