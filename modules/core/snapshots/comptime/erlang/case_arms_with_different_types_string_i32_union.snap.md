----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> "zero";
    else -> 1;
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
        }
      ],
      "return_type": "string | i32"
    }
  ]
}
```

