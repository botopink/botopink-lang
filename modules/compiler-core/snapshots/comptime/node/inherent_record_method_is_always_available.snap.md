----- SOURCE CODE -- main.bp
```botopink
record Pato {
    id: i32,
    fn quack(self: Self) {
        return self.id;
    }
}
val donald = Pato(1);
val noise = donald.quack();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Pato",
      "id": 0,
      "fields": {
        "id": "i32"
      }
    },
    {
      "ast": "val",
      "indent": "donald",
      "return_type": "Pato",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "Pato"
      }
    },
    {
      "ast": "val",
      "indent": "noise",
      "return_type": "?",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "?"
      }
    }
  ]
}
```

