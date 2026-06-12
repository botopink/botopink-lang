----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs: Array<i32> = [1, 2];
    val empty = xs.isEmpty();
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val xs: Array<i32> = [1, 2];"
        },
        {
          "source": "val empty = xs.isEmpty();"
        }
      ]
    }
  ]
}
```

