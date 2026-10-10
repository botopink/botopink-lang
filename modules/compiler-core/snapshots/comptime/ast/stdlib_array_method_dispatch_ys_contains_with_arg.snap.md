----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val ys = [1, 2, 3];
    val found = ys.contains(2);
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
          "source": "val ys = [1, 2, 3];"
        },
        {
          "source": "val found = ys.contains(2);"
        }
      ]
    }
  ]
}
```

