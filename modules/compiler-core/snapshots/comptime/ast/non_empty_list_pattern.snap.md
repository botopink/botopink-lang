----- SOURCE CODE -- main.bp
```botopink
val first_or_default = fn(list: i32[], fallback: i32) -> i32 {
    return case list {
        [first, ..] -> first;
        [] -> fallback;
    };
};
fn main() {
    @print(first_or_default([1, 2], 0));
    @print(first_or_default([], 0));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "first_or_default",
      "is_pub": false,
      "params": [
        {
          "name": "list",
          "type": "i32[]"
        },
        {
          "name": "fallback",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return case list {"
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
          "source": "@print(first_or_default([1, 2], 0));"
        },
        {
          "source": "@print(first_or_default([], 0));"
        }
      ]
    }
  ]
}
```

