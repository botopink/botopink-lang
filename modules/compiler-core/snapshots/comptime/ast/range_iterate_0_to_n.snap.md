----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    var sum = 0;
    for i in 0..n {
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
          "source": "for i in 0..n {"
        },
        {
          "source": "return sum;"
        }
      ]
    }
  ]
}
```

