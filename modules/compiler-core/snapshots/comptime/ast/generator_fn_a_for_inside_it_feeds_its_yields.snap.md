----- SOURCE CODE -- main.bp
```botopink
#[@generator]
fn doubles(arr: i32[]) -> @Generator<i32> {
    for (arr) { x ->
        yield x * 2;
    };
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "doubles",
      "is_pub": false,
      "params": [
        {
          "name": "arr",
          "type": "i32[]"
        }
      ],
      "return_type": "Generator<i32>",
      "body": [
        {
          "source": "for (arr) { x ->"
        }
      ]
    }
  ]
}
```

