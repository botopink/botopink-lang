----- SOURCE CODE -- main.bp
```botopink
fn classify(x: ?i32) -> string {
    if (x == 0) { return "zero"; }
    else if (x != 0) { return "nonzero: " + x; }
    else { return "null"; }
}
fn main() {
    @print(classify(42));
    @print(classify(null));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "classify",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": "?i32"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (x == 0) { return \"zero\"; }"
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
          "source": "@print(classify(42));"
        },
        {
          "source": "@print(classify(null));"
        }
      ]
    }
  ]
}
```

