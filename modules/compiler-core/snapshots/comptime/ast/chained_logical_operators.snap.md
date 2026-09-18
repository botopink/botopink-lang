----- SOURCE CODE -- main.bp
```botopink
val a = true && false || true;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "a",
      "return_type": "bool"
    }
  ]
}
```

