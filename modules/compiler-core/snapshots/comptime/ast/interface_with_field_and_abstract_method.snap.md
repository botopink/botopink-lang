----- SOURCE CODE -- main.bp
```botopink
val Drawable = behavior {
    val color: string;
    fn draw(self: Self);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Drawable",
      "fields": {
        "color": "string"
      },
      "methods": [
        {
          "name": "draw",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "void"
        }
      ]
    }
  ]
}
```

