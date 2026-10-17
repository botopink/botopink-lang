----- SOURCE CODE -- main.bp
```botopink
val Canvas = behavior {
    fn clear(self: Self);
    fn drawLine(self: Self, x1: i32, y1: i32);
    fn drawRect(self: Self, x: i32, y: i32, color: string);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Canvas",
      "methods": [
        {
          "name": "clear",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "drawLine",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "x1",
              "type": "i32"
            },
            {
              "name": "y1",
              "type": "i32"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "drawRect",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "x",
              "type": "i32"
            },
            {
              "name": "y",
              "type": "i32"
            },
            {
              "name": "color",
              "type": "string"
            }
          ],
          "return_type": "void"
        }
      ]
    }
  ]
}
```

