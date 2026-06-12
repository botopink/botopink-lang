----- SOURCE CODE -- main.bp
```botopink
val Option = enum <T> {
    Some(value: T),
    None,
};
val map = fn(opt: Option<i32>, f: fn(i32) -> i32) -> Option<i32> {
    case opt {
        Some(v) -> Some(value: f(v));
        None -> None;
    };
};
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
      "ast": "fn_def",
      "name": "map",
      "is_pub": false,
      "params": [
        {
          "name": "opt",
          "type": "?"
        },
        {
          "name": "f",
          "type": "?"
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "case opt {"
        }
      ]
    }
  ]
}
```

