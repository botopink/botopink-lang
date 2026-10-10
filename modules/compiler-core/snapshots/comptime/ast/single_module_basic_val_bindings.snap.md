----- SOURCE CODE -- main.bp
```botopink
val x = 42;
val name = "alice";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "x",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "ident": "name",
      "return_type": "string"
    }
  ]
}
```

