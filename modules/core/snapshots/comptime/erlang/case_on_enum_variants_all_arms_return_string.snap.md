----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Green,
    Blue,
}
val subject = Color.Red;
val label = case subject {
    Red -> "red";
    Green -> "green";
    Blue -> "blue";
    else -> "other";
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Color",
      "id": 0
    },
    {
      "ast": "val",
      "return_type": "Color"
    },
    {
      "ast": "case",
      "param": "Color",
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

