----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [] = list catch throw Error("not empty");
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
          "source": "val assert [] = list catch throw Error(\"not empty\");"
        }
      ]
    }
  ]
}
```

