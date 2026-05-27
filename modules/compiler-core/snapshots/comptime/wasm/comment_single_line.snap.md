----- SOURCE CODE -- main.bp
```botopink
// This is a comment
fn main() {
    null;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "null;"
        }
      ]
    }
  ]
}
```

