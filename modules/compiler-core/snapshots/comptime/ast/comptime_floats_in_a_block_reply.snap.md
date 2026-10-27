----- SOURCE CODE -- main.bp
```botopink
fn half(x: f64) -> f64 {
    return x / 2.0;
}
val f = comptime [half(3.0), half(0.2) + 0.2 + 0.0, 1e21, 1e-7, -0.0];
```

----- COMPTIME VALUES -- main
```text
ct_1: val f = comptime [half(3.0), half(0.2) + 0.2 + 0.0, 1e21, 1e-7, -0.0] → [1.5, 0.30000000000000004, 1000000000000000000000.0, 0.0000001, -0.0]
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
fn half(x: f64) -> f64 {
    return x / 2.0;
}

val f = [1.5, 0.30000000000000004, 1000000000000000000000.0, 0.0000001, -0.0];
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "half",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": "f64"
        }
      ],
      "return_type": "f64",
      "body": [
        {
          "source": "return x / 2.0;"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "f",
      "return_type": "f64[]"
    }
  ]
}
```

