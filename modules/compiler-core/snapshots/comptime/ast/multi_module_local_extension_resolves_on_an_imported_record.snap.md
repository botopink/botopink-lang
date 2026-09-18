----- SOURCE CODE -- pond.bp
```botopink
pub type Pato(id: i32)
```

----- TYPED AST JSON -- pond.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Pato",
      "fields": {
        "id": "i32"
      }
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {Pato} from "pond";
val Swimmer = behavior {
    fn swim(self: Self);
}
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
val donald = Pato(1);
val splash = donald.swim();
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
        "params": [],
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
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "Pato",
          "return_type": "fn(i32) -> Pato"
        }
      ]
    }
  ]
}
```

