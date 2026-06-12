----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "describe",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": [
        {
          "source": "val items = [\"a\", \"b\", \"c\"];"
        },
        {
          "source": "return case items {"
        }
      ]
    }
  ]
}
```

