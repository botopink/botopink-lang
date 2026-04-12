----- SOURCE CODE -- main.bp
```botopink
val sum = 1 + 2;
val product = 3.0 * 2.0;
val joined = "a" + "b";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "return_type": "string"
    }
  ]
}
```

