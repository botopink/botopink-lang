----- SOURCE CODE -- main.bp
```botopink
val Point = type(x: i32, y: string);
val info = comptime compiler.typeInfo(Point);

import {compiler} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Point",
      "fields": {
        "x": "i32",
        "y": "string"
      }
    },
    {
      "ast": "val",
      "ident": "info",
      "return_type": "TypeInfo<Point>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "fn(i32, string) -> Point"
          }
        ],
        "return_type": "TypeInfo<Point>"
      }
    }
  ]
}
```

