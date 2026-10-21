----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
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
          "source": "val list: i32[] = [];"
        },
        {
          "source": "val assert [] = list catch throw \"not empty\";"
        },
        {
          "source": "return;"
        }
      ]
    }
  ]
}
```

