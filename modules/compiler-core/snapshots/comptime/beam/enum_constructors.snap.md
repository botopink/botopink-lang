----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Rgb(r: i32, g: i32, b: i32),
};
val c1 = Color.Red;
val c2 = Color.Rgb(r: 255, g: 0, b: 0);
val c3: Color = .Red;
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
      "indent": "c1",
      "return_type": "Color"
    },
    {
      "ast": "val",
      "indent": "c2",
      "return_type": "Color",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "r",
            "value": "i32"
          },
          {
            "name": "g",
            "value": "i32"
          },
          {
            "name": "b",
            "value": "i32"
          }
        ],
        "return_type": "Color"
      }
    },
    {
      "ast": "val",
      "indent": "c3",
      "return_type": "Color"
    }
  ]
}
```

