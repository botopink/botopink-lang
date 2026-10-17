----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(radius: f64),
    Square(side: f64),
    Point,
}
val s = Shape.Point;
val label = case s {
    Circle(radius) -> "circle";
    Square(side)   -> "square";
    Point          -> "point";
    _           -> "other";
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Shape",
      "variants": [
        {
          "name": "Circle",
          "fields": {
            "radius": "f64"
          }
        },
        {
          "name": "Square",
          "fields": {
            "side": "f64"
          }
        },
        {
          "name": "Point"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "s",
      "return_type": "Shape"
    },
    {
      "ast": "case",
      "param": "Shape",
      "match": [
        {
          "ast": "value",
          "return_type": "string"
        },
        {
          "ast": "value",
          "return_type": "string"
        },
        {
          "ast": "value",
          "return_type": "string"
        },
        {
          "ast": "value",
          "return_type": "string"
        }
      ],
      "return_type": "string"
    }
  ]
}
```

