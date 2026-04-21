----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) {
    loop (0..n) { i ->
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
          "type": ""
        }
      ],
      "return_type": "void",
      "body": [
        {
          "source": "loop (0..n) { i ->"
        }
      ]
    }
  ]
}
```

