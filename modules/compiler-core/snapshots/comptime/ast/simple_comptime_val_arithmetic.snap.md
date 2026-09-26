----- SOURCE CODE -- main.bp
```botopink
val x = comptime 10 + 5;
val y = comptime 42;
```

----- COMPTIME VALUES -- main
```text
ct_0: val x = comptime 10 + 5 → 15
ct_1: val y = comptime 42 → 42
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
      "ident": "x",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "ident": "y",
      "return_type": "i32"
    }
  ]
}
```

