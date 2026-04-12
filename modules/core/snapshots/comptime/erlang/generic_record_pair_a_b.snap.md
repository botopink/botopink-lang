----- SOURCE CODE -- main.bp
```botopink
val Pair = record <A, B> { first: A, second: B };
val p = Pair(first: 42, second: "hello");
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
      },
      "return_type": "Pair<i32,string>"
    }
  ]
}
```

