----- SOURCE CODE -- main.bp
```botopink
type FullUser(id: i32, name: string, password: string)
val NameOnly = pick(FullUser, ["name", "id"]);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "FullUser",
      "fields": {
        "id": "i32",
        "name": "string",
        "password": "string"
      }
    },
    {
      "ast": "val",
      "ident": "NameOnly",
      "return_type": "record { name: string, id: i32 }"
    }
  ]
}
```

