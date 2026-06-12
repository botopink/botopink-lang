----- SOURCE CODE -- pond.bp
```botopink
pub record Pato { id: i32 }
```

----- TYPED AST JSON -- pond.json
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
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {Pato} from "pond";
val Swimmer = interface {
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
      "name": "Swimmer"
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
      "indent": "splash",
      "return_type": "?",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "?"
      }
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "indent": "Pato",
          "return_type": "Pato"
        }
      ]
    }
  ]
}
```

