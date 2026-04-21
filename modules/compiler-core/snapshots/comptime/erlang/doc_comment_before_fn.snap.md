----- SOURCE CODE -- main.bp
```botopink
/// This is a documented function
fn greet(name: string) -> string {
    return name;
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
          "type": ""
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return name;"
        }
      ]
    }
  ]
}
```

