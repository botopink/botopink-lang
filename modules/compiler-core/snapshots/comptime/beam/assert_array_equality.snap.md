----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert [] == [];
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
          "source": "assert [] == [];"
        }
      ]
    }
  ]
}
```

