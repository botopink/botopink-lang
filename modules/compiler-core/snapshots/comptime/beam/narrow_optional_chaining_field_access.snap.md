----- SOURCE CODE -- main.bp
```botopink
val Inner = record { value: i32 }
val Outer = record { inner: ?Inner }
fn getValue(o: Outer) -> ?i32 {
    return o.inner?.value;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Inner",
      "id": 0,
      "fields": {
        "value": "i32"
      }
    },
    {
      "ast": "record_def",
      "name": "Outer",
      "id": 0,
      "fields": {
        "inner": "?"
      }
    },
    {
      "ast": "fn_def",
      "name": "getValue",
      "is_pub": false,
      "params": [
        {
          "name": "o",
          "type": "Outer"
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "return o.inner?.value;"
        }
      ]
    }
  ]
}
```

