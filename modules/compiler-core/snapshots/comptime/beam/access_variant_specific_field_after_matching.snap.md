----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(radius: f64),
    Square(side: f64),
};
val scale = fn(s: Shape, factor: f64) -> Shape {
    case s {
        Circle(r) -> Circle(radius: r * factor);
        Square(s) -> Square(side: s * factor);
    };
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Shape",
      "id": 0
    },
    {
      "ast": "fn_def",
      "name": "scale",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "Shape"
        },
        {
          "name": "factor",
          "type": "f64"
        }
      ],
      "return_type": "Shape",
      "body": [
        {
          "source": "case s {"
        }
      ]
    }
  ]
}
```

