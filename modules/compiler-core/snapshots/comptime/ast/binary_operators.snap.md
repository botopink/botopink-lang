----- SOURCE CODE -- main.bp
```botopink
val sum = 1 + 2;
val product = 3.0 * 2.0;
val joined = "a" + "b";
fn main() {
    @print(sum, product, joined);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "sum",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "ident": "product",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "ident": "joined",
      "return_type": "string"
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(sum, product, joined);"
        }
      ]
    }
  ]
}
```

