----- SOURCE CODE -- main.bp
```botopink
val Color = type {
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
      "variants": [
        {
          "name": "Red"
        },
        {
          "name": "Blue"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "c",
      "return_type": "Color"
    }
  ]
}
```

