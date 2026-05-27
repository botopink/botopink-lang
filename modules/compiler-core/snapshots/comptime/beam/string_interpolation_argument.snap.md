----- SOURCE CODE -- main.bp
```botopink
fn greet(name: string) {
    @print("Hello, " + name + "!");
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "greet",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "void",
      "body": [
        {
          "source": "@print(\"Hello, \" + name + \"!\");"
        }
      ]
    }
  ]
}
```

