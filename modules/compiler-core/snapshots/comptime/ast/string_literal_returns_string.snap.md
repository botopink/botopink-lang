----- SOURCE CODE -- main.bp
```botopink
val greeting = "hello";
val GreetingType = @TypeOf(greeting);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "greeting",
      "return_type": "string"
    },
    {
      "ast": "val",
      "ident": "GreetingType",
      "return_type": "string",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "string"
          }
        ],
        "return_type": "string"
      }
    }
  ]
}
```

