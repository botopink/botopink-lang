----- SOURCE CODE -- main.bp
```botopink
val Triple = record <A, B, C> { first: A, second: B, third: C };
val t = Triple(first: 1, second: "x", third: 3.14);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Triple",
      "id": 0,
      "generic": [
        "A",
        "B",
        "C"
      ],
      "fields": {
        "first": "A",
        "second": "B",
        "third": "C"
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
          },
          {
            "name": "third",
            "value": "f64"
          }
        ],
        "return_type": "Triple<i32,string,f64>"
      },
      "return_type": "Triple<i32,string,f64>"
    }
  ]
}
```

