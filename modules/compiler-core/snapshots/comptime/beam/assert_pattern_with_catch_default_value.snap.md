----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "f",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "val assert Person(name, age) = r catch Person(name: \"bob\", age: 12);"
        }
      ]
    }
  ]
}
```

