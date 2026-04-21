----- SOURCE CODE -- main.bp
```botopink
fn greet(name: ?string) -> string {
    return if (name) { n -> n; } else { "anonymous"; };
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "greet",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": ""
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return if (name) { n -> n; } else { \"anonymous\"; };"
        }
      ]
    }
  ]
}
```

