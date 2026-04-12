----- SOURCE CODE -- main.bp
```botopink
val label = case 42 {
    0 -> "zero";
    1 -> "one";
    else -> "many";
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
        },
        {
          "ast": "value",
          "return_type": "string"
        }
      ],
      "return_type": "string"
    }
  ]
}
```

