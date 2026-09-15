----- SOURCE CODE -- main.bp
```botopink
val x = comptime 10 + 5;
val y = comptime 42;
```

----- COMPTIME VALUES -- main
```text
ct_0 = 15
ct_1 = 42
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val x = 15;

val y = 42;
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
      "return_type": "i32"
    }
  ]
}
```

