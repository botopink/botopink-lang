----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> {
      case 1 {
          0    -> 54;
          else -> 1;
      };
   };
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
          "ast": "block",
          "body": [
            {
              "return_type": "i32"
            }
          ],
          "return_type": "?"
        },
        {
          "ast": "value",
          "return_type": "i32"
        }
      ],
      "return_type": "? | i32"
    }
  ]
}
```

