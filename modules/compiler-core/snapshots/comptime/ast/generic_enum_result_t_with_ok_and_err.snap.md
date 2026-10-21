----- SOURCE CODE -- main.bp
```botopink
val Result = type <T> {
    Ok(value: T),
    Err(message: string),
};
pub fn isOk<T>(r: Result<T>) -> bool {
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
      "generic": [
        "T"
      ],
      "variants": [
        {
          "name": "Ok",
          "fields": {
            "value": "T"
          }
        },
        {
          "name": "Err",
          "fields": {
            "message": "string"
          }
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "isOk",
      "is_pub": true,
      "generic_params": [
        "T"
      ],
      "params": [
        {
          "name": "r",
          "type": "Result<'a>"
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
      "ident": "r",
      "return_type": "Result<i32>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "value",
            "value": "i32"
          }
        ],
        "return_type": "Result<i32>"
      }
    },
    {
      "ast": "val",
      "ident": "ok",
      "return_type": "bool",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Result<i32>"
          }
        ],
        "return_type": "bool"
      }
    }
  ]
}
```

