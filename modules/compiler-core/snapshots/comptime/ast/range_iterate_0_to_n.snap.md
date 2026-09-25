----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    var sum = 0;
    for (0..n) { i ->
        sum = sum + i;
    };
    return sum;
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "sumTo",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "var sum = 0;"
        },
        {
          "source": "for (0..n) { i ->"
        },
        {
          "source": "return sum;"
        }
      ]
    }
  ]
}
```

