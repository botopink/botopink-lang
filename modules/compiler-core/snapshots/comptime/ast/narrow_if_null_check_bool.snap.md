----- SOURCE CODE -- main.bp
```botopink
fn and(a: ?bool, b: ?bool) -> bool {
    if (a) { va ->
        if (b) { vb ->
            return va && vb;
        };
    };
    return false;
}
fn main() {
    @print(and(true, true));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "and",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": "?"
        },
        {
          "name": "b",
          "type": "?"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "if (a) { va ->"
        },
        {
          "source": "return false;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(and(true, true));"
        }
      ]
    }
  ]
}
```

