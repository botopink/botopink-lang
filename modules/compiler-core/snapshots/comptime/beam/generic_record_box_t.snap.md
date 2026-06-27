----- SOURCE CODE -- main.bp
```botopink
val Box = record <T> {
    value: T = todo,
};
val b = Box(42);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Box",
      "id": 0,
      "generic": [
        "T"
      ],
      "fields": {
        "value": "T"
      }
    },
    {
      "ast": "val",
      "indent": "b",
      "return_type": "Box<i32>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "Box<i32>"
      }
    }
  ]
}
```

