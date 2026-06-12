----- SOURCE CODE -- pond.bp
```botopink
val Swimmer = interface {
    fn swim(self: Self);
}
pub record Pato { id: i32 }
pub val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
```

----- TYPED AST JSON -- pond.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Swimmer"
    },
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
import {Pato, PatoNada*} from "pond";
val donald = Pato(1);
val splash = donald.swim();
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
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

