----- SOURCE CODE -- main.bp
```botopink
pub fn repeat(s comptime: string, n comptime: i32) -> string {
    @todo();
}
val r = repeat("hi", 3);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "repeat",
      "is_pub": true,
      "params": [
        {
          "name": "s",
          "type": "",
          "is_comptime": true
        },
        {
          "name": "n",
          "type": "",
          "is_comptime": true
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "@todo();"
        }
      ]
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "string"
          },
          {
            "value": "i32"
          }
        ],
        "return_type": "string"
      },
      "return_type": "string"
    }
  ]
}
```

