----- SOURCE CODE -- main.bp
```botopink
val desc = case 42 {
    0 -> "zero";
    _ -> "nonzero";
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
          "return_type": "string"
        }
      ],
      "return_type": "?"
    }
  ]
}
```

