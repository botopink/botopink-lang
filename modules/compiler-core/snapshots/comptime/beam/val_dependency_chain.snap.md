----- SOURCE CODE -- main.bp
```botopink
val a = 10;
val b = a + 5;
val c = b + a;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "a",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "b",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "c",
      "return_type": "i32"
    }
  ]
}
```

