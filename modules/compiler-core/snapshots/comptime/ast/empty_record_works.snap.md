----- SOURCE CODE -- main.bp
```botopink
type Empty()
val PartialE = partial(Empty);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Empty",
      "fields": {}
    },
    {
      "ast": "val",
      "ident": "PartialE",
      "return_type": "record {  }"
    }
  ]
}
```

