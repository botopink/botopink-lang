----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    count: i32 = 0,
};
val c = Counter(0);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "struct_def",
      "name": "Counter",
      "id": 0,
      "fields": {
        "count": "i32"
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
        "return_type": "Counter"
      },
      "return_type": "Counter"
    }
  ]
}
```

