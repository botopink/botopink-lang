----- SOURCE CODE -- main.bp
```botopink
val greeting = "hello";
fn main() {
    @print(greeting);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "greeting",
      "return_type": "string"
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(greeting);"
        }
      ]
    }
  ]
}
```

