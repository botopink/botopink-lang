----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [1, 2, 3] = numbers catch throw Error("not matching");
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
          "source": "val assert [1, 2, 3] = numbers catch throw Error(\"not matching\");"
        }
      ]
    }
  ]
}
```

