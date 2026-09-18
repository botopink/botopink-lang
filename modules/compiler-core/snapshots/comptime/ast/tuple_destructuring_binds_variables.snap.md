----- SOURCE CODE -- main.bp
```botopink
fn extract() {
    val #(first, second) = #(1, "hello");
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "extract",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val #(first, second) = #(1, \"hello\");"
        }
      ]
    }
  ]
}
```

