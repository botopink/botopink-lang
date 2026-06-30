----- SOURCE CODE -- main.bp
```botopink
enum Animal {
    Dog(breed: string),
    Cat(breed: string),
    Fish,
}
fn breed(a: Animal) -> string {
    return case a {
        Dog(b) | Cat(b) -> b;
        Fish -> "none";
    };
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Animal",
      "id": 0
    },
    {
      "ast": "fn_def",
      "name": "breed",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": "Animal"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case a {"
        }
      ]
    }
  ]
}
```

