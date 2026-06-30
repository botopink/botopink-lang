----- SOURCE CODE -- main.bp
```botopink
record FullUser { id: i32, name: string, password: string }
val PublicUser = omit(FullUser, "password");
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "FullUser",
      "id": 0,
      "fields": {
        "id": "i32",
        "name": "string",
        "password": "string"
      }
    },
    {
      "ast": "val",
      "indent": "PublicUser",
      "return_type": "record { id: i32, name: string }"
    }
  ]
}
```

