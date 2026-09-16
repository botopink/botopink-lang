----- SOURCE CODE -- main.bp
```botopink
pub fn compute(x: i32) -> i32 {
    val doubled = x + x;
    @print(doubled);
    return doubled;
}
val result = compute(21);
fn main() {
    @print(result);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "compute",
      "is_pub": true,
      "params": [
        {
          "name": "x",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "val doubled = x + x;"
        },
        {
          "source": "@print(doubled);"
        },
        {
          "source": "return doubled;"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "result",
      "return_type": "i32",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "i32"
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
          "source": "@print(result);"
        }
      ]
    }
  ]
}
```

