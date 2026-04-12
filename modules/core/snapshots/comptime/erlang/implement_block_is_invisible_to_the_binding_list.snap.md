----- SOURCE CODE -- main.bp
```botopink
val Drawable = interface {
    fn draw(self: Self);
};
val Circle = record { radius: f64 };
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {
        todo;
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
      "name": "Drawable"
    },
    {
      "ast": "record_def",
      "name": "Circle",
      "id": 0,
      "fields": {
        "radius": "f64"
      }
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "radius",
            "value": "f64"
          }
        ],
        "return_type": "Circle"
      },
      "return_type": "Circle"
    }
  ]
}
```

