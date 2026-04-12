----- SOURCE CODE -- main.bp
```botopink
val x = case 0 {
    0 -> "zero";
    1 -> 42;
    else -> 3.14;
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "case",
      "param": "i32",
      "match": [
        {
          "ast": "value",
          "return_type": "string"
        },
        {
          "ast": "value",
          "return_type": "i32"
        },
        {
          "ast": "value",
          "return_type": "f64"
        }
      ],
      "return_type": "string | i32 | f64"
    }
  ]
}
```

