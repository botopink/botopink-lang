----- SOURCE CODE -- main.bp
```botopink
val list3 = [1, 2, ..[3, 4]];
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "list3",
      "return_type": "i32[]"
    }
  ]
}
```

