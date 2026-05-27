----- SOURCE CODE -- main.bp
```botopink
val Canvas = interface {
    fn clear(self: Self),
    fn drawLine(self: Self, x1: i32, y1: i32),
    fn drawRect(self: Self, x: i32, y: i32, color: string),
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Canvas"
    }
  ]
}
```

