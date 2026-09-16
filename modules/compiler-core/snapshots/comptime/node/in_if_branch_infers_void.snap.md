----- SOURCE CODE -- main.bp
```botopink
fn check(x: i32) {
    if (x > 0) {
        @print("positive");
    } else {
        @print("non-positive");
    }
}
fn main() {
    check(1);
    check(-1);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "check",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": "i32"
        }
      ],
      "return_type": "void",
      "body": [
        {
          "source": "if (x > 0) {"
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
          "source": "check(1);"
        },
        {
          "source": "check(-1);"
        }
      ]
    }
  ]
}
```

