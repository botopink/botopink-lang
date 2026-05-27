----- SOURCE CODE -- main.bp
```botopink
val Result = enum {
    Ok(value: i32),
    Error(message: string),
};
val get_value = fn(r: Result) -> i32 {
    case r {
        Ok(v) -> v;
        Error(_) -> 0;
    }
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Result",
      "id": 0
    },
    {
      "ast": "fn_def",
      "name": "get_value",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "Result"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "case r {"
        }
      ]
    }
  ]
}
```

