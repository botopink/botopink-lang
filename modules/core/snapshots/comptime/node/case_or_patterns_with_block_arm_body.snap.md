----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    else      -> {
        val value = "odd";
        break value;
    };
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
          "ast": "block",
          "body": [
            {
              "return_type": "string"
            },
            {
              "return_type": "string"
            }
          ],
          "return_type": "?"
        }
      ],
      "return_type": "string | ?"
    }
  ]
}
```

