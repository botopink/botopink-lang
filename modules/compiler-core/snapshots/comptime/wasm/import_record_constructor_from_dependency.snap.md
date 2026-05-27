----- SOURCE CODE -- models.bp
```botopink
record Point { x: i32, y: i32 }
```

----- TYPED AST JSON -- models.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Point",
      "id": 0,
      "fields": {
        "x": "i32",
        "y": "i32"
      }
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
use {Point} from "models";
val origin = Point(0, 0);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "origin",
      "return_type": "Point",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          },
          {
            "value": "i32"
          }
        ],
        "return_type": "Point"
      }
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "indent": "Point",
          "return_type": "Point"
        }
      ]
    }
  ]
}
```

