----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() -> Result<void, string> {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch throw "is not person";
    return;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Person",
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
      "return_type": "Result<void,string>",
      "body": [
        {
          "source": "val r = Person(name: \"ann\", age: 30);"
        },
        {
          "source": "val assert Person(name, age) = r catch throw \"is not person\";"
        },
        {
          "source": "return;"
        }
      ]
    }
  ]
}
```

