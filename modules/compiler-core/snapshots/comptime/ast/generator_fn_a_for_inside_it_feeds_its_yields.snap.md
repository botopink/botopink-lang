----- SOURCE CODE -- main.bp
```botopink
iter fn doubles(arr: i32[]) -> Iter<i32> {
    for x in arr {
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
      "return_type": "Iter<i32>",
      "body": [
        {
          "source": "for x in arr {"
        }
      ]
    }
  ]
}
```

