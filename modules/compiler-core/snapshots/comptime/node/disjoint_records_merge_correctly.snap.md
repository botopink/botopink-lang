----- SOURCE CODE -- main.bp
```botopink
record User { name: string, id: i32 }
record Timestamps { createdAt: string, updatedAt: string }
val Merged = mergeRecords(User, Timestamps);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "User",
      "id": 0,
      "fields": {
        "name": "string",
        "id": "i32"
      }
    },
    {
      "ast": "record_def",
      "name": "Timestamps",
      "id": 0,
      "fields": {
        "createdAt": "string",
        "updatedAt": "string"
      }
    },
    {
      "ast": "val",
      "indent": "Merged",
      "return_type": "record { name: string, id: i32, createdAt: string, updatedAt: string }"
    }
  ]
}
```

