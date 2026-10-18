----- SOURCE CODE -- main.bp
```botopink
val Drawable = behavior {
    fn draw(self: Self);
};
val Circle = type(radius: f64);
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {
        panic("not implemented");
    }
};
val c = Circle(radius: 5.0);

import {failure.panic} from "std";
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

