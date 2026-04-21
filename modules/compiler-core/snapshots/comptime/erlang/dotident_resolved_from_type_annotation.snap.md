----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Blue,
};
val c: Color = .Red;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Color",
      "id": 0
    },
    {
      "ast": "val",
      "return_type": "Color"
    }
  ]
}
```

