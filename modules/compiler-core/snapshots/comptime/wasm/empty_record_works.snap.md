----- SOURCE CODE -- main.bp
```botopink
record Empty {}
val PartialE = partial(Empty);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Empty",
      "id": 0,
      "fields": {}
    },
    {
      "ast": "val",
      "indent": "PartialE",
      "return_type": "record {  }"
    }
  ]
}
```

