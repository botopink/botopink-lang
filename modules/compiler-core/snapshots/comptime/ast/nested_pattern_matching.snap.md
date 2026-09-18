----- SOURCE CODE -- main.bp
```botopink
val Result = type <T, E> {
    Ok(value: T),
    Err(error: E),
};
val unwrap_or = fn(r: Result<i32, string>, fallback: i32) -> i32 {
    case r {
        Ok(v) -> v,
        Err(_) -> fallback,
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
      "id": 0,
      "generic": [
        "T",
        "E"
      ]
    },
    {
      "ast": "fn_def",
      "name": "unwrap_or",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "Result<i32,string>"
        },
        {
          "name": "fallback",
          "type": "i32"
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

