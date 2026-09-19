----- SOURCE CODE -- main.bp
```botopink
type User(name: string, id: i32)
type Timestamps(createdAt: string, updatedAt: string)
val Merged = mergeRecords(User, Timestamps);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "User",
      "fields": {
        "name": "string",
        "id": "i32"
      }
    },
    {
      "ast": "record_def",
      "name": "Timestamps",
      "fields": {
        "createdAt": "string",
        "updatedAt": "string"
      }
    },
    {
      "ast": "val",
      "ident": "Merged",
      "return_type": "record { name: string, id: i32, createdAt: string, updatedAt: string }"
    }
  ]
}
```

