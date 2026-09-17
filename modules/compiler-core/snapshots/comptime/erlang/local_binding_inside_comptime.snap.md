----- SOURCE CODE -- main.bp
```botopink
val hash = comptime { break 6364 + 11; };
```

----- COMPTIME VALUES -- main
```text
ct_0: val hash = comptime {
          break 6364 + 11;
      } → 6375
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val hash = comptime {
    break 6364 + 11;
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "hash",
      "return_type": "i32"
    }
  ]
}
```

