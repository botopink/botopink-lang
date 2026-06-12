----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("x =", 42, true);
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
          "source": "@print(\"x =\", 42, true);"
        }
      ]
    }
  ]
}
```

