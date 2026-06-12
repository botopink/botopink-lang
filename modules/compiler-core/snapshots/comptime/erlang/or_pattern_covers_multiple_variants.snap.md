----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Green,
    Blue,
};
val warm = fn(c: Color) -> bool {
    case c {
        Red | Green -> true;
        Blue -> false;
    }
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
      "ast": "fn_def",
      "name": "warm",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "Color"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "case c {"
        }
      ]
    }
  ]
}
```

