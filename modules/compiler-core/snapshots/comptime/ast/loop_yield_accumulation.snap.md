----- SOURCE CODE -- main.bp
```botopink
fn doubles(arr: i32[]) -> i32[] {
    return for (arr) { x ->
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
      "return_type": "i32[]",
      "body": [
        {
          "source": "return for (arr) { x ->"
        }
      ]
    }
  ]
}
```

