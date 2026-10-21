----- SOURCE CODE -- main.bp
```botopink
val answer: i32 = 42;
val AnswerType = @TypeOf(answer);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "answer",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "ident": "AnswerType",
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
    }
  ]
}
```

