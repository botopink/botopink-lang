----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    case c {
        Red -> "red";
        _ -> "other";
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
      "name": "name",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "Color"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "case c {"
        }
      ]
    }
  ]
}
```

