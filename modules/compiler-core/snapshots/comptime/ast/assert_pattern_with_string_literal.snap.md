----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
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
          "source": "val greeting = \"hello\";"
        },
        {
          "source": "val assert \"hello\" = greeting catch throw \"not hello\";"
        },
        {
          "source": "return;"
        }
      ]
    }
  ]
}
```

