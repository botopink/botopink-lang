----- SOURCE CODE -- main.bp
```botopink
fn find(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x > 10) { break x; };
    };
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "find",
      "is_pub": false,
      "params": [
        {
          "name": "arr",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return loop (arr) { x ->"
        }
      ]
    }
  ]
}
```

