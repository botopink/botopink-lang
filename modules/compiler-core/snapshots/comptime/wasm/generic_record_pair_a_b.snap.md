----- SOURCE CODE -- main.bp
```botopink
val Pair = record <A, B> { first: A, second: B };
val p = Pair(first: 42, second: "hello");
fn main() {
    @print(p);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Pair",
      "id": 0,
      "generic": [
        "A",
        "B"
      ],
      "fields": {
        "first": "A",
        "second": "B"
      }
    },
    {
      "ast": "val",
      "indent": "p",
      "return_type": "Pair<i32,string>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "first",
            "value": "i32"
          },
          {
            "name": "second",
            "value": "string"
          }
        ],
        "return_type": "Pair<i32,string>"
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
          "source": "@print(p);"
        }
      ]
    }
  ]
}
```

