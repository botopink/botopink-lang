----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) {
    for (0..n) { i ->
        yield i;
    };
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
      "return_type": "void",
      "body": [
        {
          "source": "for (0..n) { i ->"
        }
      ]
    }
  ]
}
```

