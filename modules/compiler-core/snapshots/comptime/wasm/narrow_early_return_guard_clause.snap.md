----- SOURCE CODE -- main.bp
```botopink
fn greet(x: ?string) -> string {
    if (x == null) { return "nobody"; };
    return "hello " + x;
}
fn main() {
    @print(greet("world"));
    @print(greet(null));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "greet",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": "?"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (x == null) { return \"nobody\"; };"
        },
        {
          "source": "return \"hello \" + x;"
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
          "source": "@print(greet(\"world\"));"
        },
        {
          "source": "@print(greet(null));"
        }
      ]
    }
  ]
}
```

