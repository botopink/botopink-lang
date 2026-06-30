----- SOURCE CODE -- main.bp
```botopink
record A { x: i32, y: string }
record B { x: i32, z: bool }
val Merged = mergeRecords(A, B);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "A",
      "id": 0,
      "fields": {
        "x": "i32",
        "y": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "B",
      "id": 0,
      "fields": {
        "x": "i32",
        "z": "bool"
      }
    },
    {
      "ast": "val",
      "indent": "Merged",
      "return_type": "record { x: i32, y: string, z: bool }"
    }
  ]
}
```

