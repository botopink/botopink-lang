----- SOURCE CODE -- main.bp
```botopink
val Swimmer = behavior {
    fn swim(self: Self);
}
type Pato(id: i32)
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
val donald = Pato(1);
val splash = PatoNada.swim(donald);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Swimmer",
      "methods": [
        {
          "name": "swim",
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
      "ast": "record_def",
      "name": "Pato",
      "fields": {
        "id": "i32"
      }
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
      "ident": "splash",
      "return_type": "?",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Pato"
          }
        ],
        "return_type": "?"
      }
    },
    {
      "ast": "implement_def",
      "name": "PatoNada",
      "interfaces": [
        "Swimmer"
      ],
      "target": "Pato",
      "methods": [
        {
          "name": "swim",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ]
        }
      ]
    }
  ]
}
```

