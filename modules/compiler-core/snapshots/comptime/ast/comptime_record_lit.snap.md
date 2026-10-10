----- SOURCE CODE -- main.bp
```botopink
type RecordField(name: string, typeName: string)
val f = comptime RecordField(name: "x", typeName: "i32");
```

----- COMPTIME VALUES -- main
```text
ct_1: val f = comptime RecordField(name: "x", typeName: "i32") → RecordField(name: "x", typeName: "i32")
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
type RecordField(name: string, typeName: string)

val f = RecordField(name: "x", typeName: "i32");
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "RecordField",
      "fields": {
        "name": "string",
        "typeName": "string"
      }
    },
    {
      "ast": "val",
      "ident": "f",
      "return_type": "RecordField"
    }
  ]
}
```

