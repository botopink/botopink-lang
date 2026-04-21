----- SOURCE CODE -- main.bp
```botopink
fn doubles(arr: i32[]) -> i32[] {
    return loop (arr) { x ->
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
          "type": ""
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "return loop (arr) { x ->"
        }
      ]
    }
  ]
}
```

