----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Green,
    Blue,
}
val subject = Color.Red;
val label = case subject {
    Red -> "red";
    Green -> "green";
    Blue -> "blue";
    _ -> "other";
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Color",
      "variants": [
        {
          "name": "Red"
        },
        {
          "name": "Green"
        },
        {
          "name": "Blue"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "subject",
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

