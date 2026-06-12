----- SOURCE CODE -- main.bp
```botopink
val Point = struct {
    x: i32,
    y: i32,
    fn sum() -> i32 {
        return self.x + self.y;
    },
};
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

