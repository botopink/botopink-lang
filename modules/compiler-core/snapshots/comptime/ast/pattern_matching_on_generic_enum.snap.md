----- SOURCE CODE -- main.bp
```botopink
val Option = type <T> {
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
      "generic": [
        "T"
      ],
      "variants": [
        {
          "name": "Some",
          "fields": {
            "value": "T"
          }
        },
        {
          "name": "None"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "map",
      "is_pub": false,
      "params": [
        {
          "name": "opt",
          "type": "Option<i32>"
        },
        {
          "name": "f",
          "type": "fn(i32) -> i32"
        }
      ],
      "return_type": "Option<i32>",
      "body": [
        {
          "source": "case opt {"
        }
      ]
    }
  ]
}
```

