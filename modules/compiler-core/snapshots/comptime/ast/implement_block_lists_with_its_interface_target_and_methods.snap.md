----- SOURCE CODE -- main.bp
```botopink
val Drawable = behavior {
    fn draw(self: Self);
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {
        @todo();
    }
};
val c = Circle(radius: 5.0);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Drawable",
      "methods": [
        {
          "name": "draw",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "void"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "Circle",
      "fields": {
        "radius": "f64"
      }
    },
    {
      "ast": "val",
      "ident": "c",
      "return_type": "Circle",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "radius",
            "value": "f64"
          }
        ],
        "return_type": "Circle"
      }
    },
    {
      "ast": "implement_def",
      "name": "CircleDrawing",
      "interfaces": [
        "Drawable"
      ],
      "target": "Circle",
      "methods": [
        {
          "name": "draw",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ]
        }
      ]
    }
  ]
}
```

