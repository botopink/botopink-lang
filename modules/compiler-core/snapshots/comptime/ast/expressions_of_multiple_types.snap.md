----- SOURCE CODE -- main.bp
```botopink
val pi      = comptime 3.14 * 2.0;
val maxVal  = comptime 100 + 1;
val banner  = comptime "Hello, " + "World";
```

----- COMPTIME VALUES -- main
```text
ct_0: val pi = comptime 3.14 * 2.0 → 6.28
ct_1: val maxVal = comptime 100 + 1 → 101
ct_2: val banner = comptime "Hello, " + "World" → "Hello, World"
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val pi = 6.28;

val maxVal = 101;

val banner = "Hello, World";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "pi",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "indent": "maxVal",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "banner",
      "return_type": "string"
    }
  ]
}
```

