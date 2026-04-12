----- SOURCE CODE -- main.bp
```botopink
val Box = struct <T> {
    value: T = todo,
};
val b = Box(42);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "struct_def",
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
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "Box"
      },
      "return_type": "Box"
    }
  ]
}
```

