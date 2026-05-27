----- SOURCE CODE -- main.bp
```botopink
val Option = enum <T> {
    None,
    Some(value: T),
};
val n = Option.None;
val s = Option.Some(value: 42);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Option",
      "id": 0,
      "generic": [
        "T"
      ]
    },
    {
      "ast": "val",
      "indent": "n",
      "return_type": "Option"
    },
    {
      "ast": "val",
      "indent": "s",
      "return_type": "Option",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "value",
            "value": "i32"
          }
        ],
        "return_type": "Option"
      }
    }
  ]
}
```

