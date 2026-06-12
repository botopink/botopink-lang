----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x = 10;
    @print(x + 5);
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
          "source": "val x = 10;"
        },
        {
          "source": "@print(x + 5);"
        }
      ]
    }
  ]
}
```

