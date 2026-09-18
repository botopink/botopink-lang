----- SOURCE CODE -- main.bp
```botopink
val x: i32 = 42;
val y: f64 = 3.14;
val msg: string = "hello";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "x",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "y",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "indent": "msg",
      "return_type": "string"
    }
  ]
}
```

