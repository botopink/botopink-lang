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

