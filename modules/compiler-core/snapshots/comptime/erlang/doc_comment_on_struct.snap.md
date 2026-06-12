----- SOURCE CODE -- main.bp
```botopink
//// A point in 2D space
val Point = struct { x: i32, y: i32 };
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "struct_def",
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

