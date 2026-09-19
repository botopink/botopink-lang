----- SOURCE CODE -- main.bp
```botopink
type Shape {
    Circle(radius: f64),
    Rectangle(w: f64, h: f64),
    Point,
}
fn area(s: Shape) -> f64 {
    return case s {
        Circle(radius) -> 3.14 * radius * radius;
        Rectangle(w, h) -> w * h;
        Point -> 0.0;
    };
}
fn main() {
    @print(area(Shape.Circle(2.0)));
}
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
          "name": "Rectangle",
          "fields": {
            "w": "f64",
            "h": "f64"
          }
        },
        {
          "name": "Point"
        }
      ]
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
          "source": "return case s {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(area(Shape.Circle(2.0)));"
        }
      ]
    }
  ]
}
```

