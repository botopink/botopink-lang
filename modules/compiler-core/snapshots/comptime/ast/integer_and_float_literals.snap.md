----- SOURCE CODE -- main.bp
```botopink
val x = 42;
val y = 3.14;
fn main() {
    @print(x, y);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "x",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "y",
      "return_type": "f64"
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(x, y);"
        }
      ]
    }
  ]
}
```

