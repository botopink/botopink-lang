----- SOURCE CODE -- main.bp
```botopink
val list2 = [1, 2, ..[3]];
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "list2",
      "return_type": "i32[]"
    }
  ]
}
```

