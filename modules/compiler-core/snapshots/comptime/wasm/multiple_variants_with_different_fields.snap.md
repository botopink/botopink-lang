----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(radius: f64),
    Rectangle(width: f64, height: f64),
    Point,
};
val area = fn(s: Shape) -> f64 {
    case s {
        Circle(r) -> 3.14 * r * r;
        Rectangle(w, h) -> w * h;
        Point -> 0.0;
    }
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
      "name": "area",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "Shape"
        }
      ],
      "return_type": "f64",
      "body": [
        {
          "source": "case s {"
        }
      ]
    }
  ]
}
```

