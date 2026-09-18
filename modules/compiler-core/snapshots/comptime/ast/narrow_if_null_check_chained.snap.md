----- SOURCE CODE -- main.bp
```botopink
type Inner(c: i32)
type Outer(b: ?Inner)
fn getC(o: ?Outer) -> i32 {
    if (o) { outer ->
        if (outer.b) { inner ->
            return inner.c;
        };
    };
    return 0;
}
fn main() {
    @print(getC(Outer(b: Inner(c: 7))));
    @print(getC(Outer(b: null)));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Inner",
      "id": 0,
      "fields": {
        "c": "i32"
      }
    },
    {
      "ast": "record_def",
      "name": "Outer",
      "id": 0,
      "fields": {
        "b": "?Inner"
      }
    },
    {
      "ast": "fn_def",
      "name": "getC",
      "is_pub": false,
      "params": [
        {
          "name": "o",
          "type": "?Outer"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "if (o) { outer ->"
        },
        {
          "source": "return 0;"
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
          "source": "@print(getC(Outer(b: Inner(c: 7))));"
        },
        {
          "source": "@print(getC(Outer(b: null)));"
        }
      ]
    }
  ]
}
```

