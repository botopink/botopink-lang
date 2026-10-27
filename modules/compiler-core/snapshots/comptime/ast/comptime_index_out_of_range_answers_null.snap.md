----- SOURCE CODE -- main.bp
```botopink
val m = comptime {
    val xs = [1, 2, 3];
    xs[9]
};
```

----- COMPTIME VALUES -- main
```text
ct_0: val m = comptime {
          val xs = [1, 2, 3];
          xs[9]
      } → null
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val m = null;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "m",
      "return_type": "?i32"
    }
  ]
}
```

