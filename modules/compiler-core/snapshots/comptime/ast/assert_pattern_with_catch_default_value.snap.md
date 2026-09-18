----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
}
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
        "age": "i32"
      }
    },
    {
      "ast": "fn_def",
      "name": "f",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val r = Person(name: \"ann\", age: 30);"
        },
        {
          "source": "val assert Person(name, age) = r catch Person(name: \"bob\", age: 12);"
        }
      ]
    }
  ]
}
```

