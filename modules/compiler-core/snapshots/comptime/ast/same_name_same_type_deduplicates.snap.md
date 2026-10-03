----- SOURCE CODE -- main.bp
```botopink
type A(x: i32, y: string)
type B(x: i32, z: bool)
val Merged = mergeRecords(A, B);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "A",
      "fields": {
        "x": "i32",
        "y": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "B",
      "fields": {
        "x": "i32",
        "z": "bool"
      }
    },
    {
      "ast": "val",
      "ident": "Merged",
      "return_type": "record { x: i32, y: string, z: bool }"
    }
  ]
}
```

