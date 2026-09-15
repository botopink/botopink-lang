----- SOURCE CODE -- main.bp
```botopink
fn isString(x: ?string) -> x is string {
    if (x) { s -> return true; };
    return false;
}
fn main() {
    @print(isString("hello"));
    @print(isString(null));
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "isString",
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
          "source": "if (x) { s -> return true; };"
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
          "source": "@print(isString(\"hello\"));"
        },
        {
          "source": "@print(isString(null));"
        }
      ]
    }
  ]
}
```

