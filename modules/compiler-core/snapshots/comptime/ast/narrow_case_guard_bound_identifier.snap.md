----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return case n {
        x if (x > 0) -> "positive: " + x;
        x if (x < 0) -> "negative: " + x;
        _ -> "zero";
    };
}
fn main() {
    @print(describe(5));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "describe",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "i32"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case n {"
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
          "source": "@print(describe(5));"
        }
      ]
    }
  ]
}
```

