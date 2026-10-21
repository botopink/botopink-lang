----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
    return;
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
      "return_type": "Result<void,string>",
      "body": [
        {
          "source": "val answer = 42;"
        },
        {
          "source": "val assert 42 = answer catch throw \"not 42\";"
        },
        {
          "source": "return;"
        }
      ]
    }
  ]
}
```

