----- SOURCE CODE -- main.bp
```botopink
type Pato(
    id: i32) {
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
      "fields": {
        "id": "i32"
      },
      "methods": [
        {
          "name": "quack",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "void"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "donald",
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
      "ident": "noise",
      "return_type": "i32",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "i32"
      }
    }
  ]
}
```

