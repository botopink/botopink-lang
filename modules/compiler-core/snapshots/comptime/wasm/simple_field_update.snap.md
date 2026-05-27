----- SOURCE CODE -- main.bp
```botopink
val Person = record {
    name: string,
    age: i32,
    city: string,
};
val alice = Person(name: "Alice", age: 30, city: "London");
val bob = Person(..alice, name: "Bob", age: 25);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Person",
      "id": 0,
      "fields": {
        "name": "string",
        "age": "i32",
        "city": "string"
      }
    },
    {
      "ast": "val",
      "indent": "alice",
      "return_type": "Person",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "name",
            "value": "string"
          },
          {
            "name": "age",
            "value": "i32"
          },
          {
            "name": "city",
            "value": "string"
          }
        ],
        "return_type": "Person"
      }
    },
    {
      "ast": "val",
      "indent": "bob",
      "return_type": "Person",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "..",
            "value": "Person"
          },
          {
            "name": "name",
            "value": "string"
          },
          {
            "name": "age",
            "value": "i32"
          }
        ],
        "return_type": "Person"
      }
    }
  ]
}
```

