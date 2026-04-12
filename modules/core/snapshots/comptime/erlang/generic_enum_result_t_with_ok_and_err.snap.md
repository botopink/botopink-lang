----- SOURCE CODE -- main.bp
```botopink
val Result = enum <T> {
    Ok(value: T),
    Err(message: string),
};
pub fn isOk(r: Result) -> bool {
    return true;
}
val r = Result.Ok(value: 42);
val ok = isOk(r);
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
        "T"
      ]
    },
    {
      "ast": "fn_def",
      "name": "isOk",
      "is_pub": true,
      "params": [
        {
          "name": "r",
          "type": "Result"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return true;"
        }
      ]
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "value",
            "value": "i32"
          }
        ],
        "return_type": "Result"
      },
      "return_type": "Result"
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Result"
          }
        ],
        "return_type": "bool"
      },
      "return_type": "bool"
    }
  ]
}
```

