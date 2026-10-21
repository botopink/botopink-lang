----- SOURCE CODE -- main.bp
```botopink
val hash = comptime { 6364 + 11 };
```

----- COMPTIME VALUES -- main
```text
ct_0: val hash = comptime { 6364 + 11 } → 6375
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val hash = 6375;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "hash",
      "return_type": "i32"
    }
  ]
}
```

