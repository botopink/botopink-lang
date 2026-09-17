----- SOURCE CODE -- main.bp
```botopink
type Point(
    x: i32,
    y: i32) {
    fn sum(self: Self) -> i32 {
        return self.x + self.y;
    }
}
fn main() {
    @print(Point(x: 1, y: 2).sum());
}
```

----- TYPED AST JSON -- main.json
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
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(Point(x: 1, y: 2).sum());"
        }
      ]
    }
  ]
}
```

