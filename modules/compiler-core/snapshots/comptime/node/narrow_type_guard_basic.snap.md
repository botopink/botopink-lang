----- SOURCE CODE -- main.bp
```botopink
fn isPositive(n: i32) -> n is i32 {
    return n > 0;
}
fn main() {
    @print(isPositive(5));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "isPositive",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return n > 0;"
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
          "source": "@print(isPositive(5));"
        }
      ]
    }
  ]
}
```

