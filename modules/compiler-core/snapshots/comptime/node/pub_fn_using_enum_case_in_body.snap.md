----- SOURCE CODE -- main.bp
```botopink
val Direction = enum {
    North,
    South,
    East,
    West,
}
pub fn label(d: Direction) -> string {
    val result = case d {
        North -> "N";
        South -> "S";
        East -> "E";
        West -> "W";
        _ -> "?";
    };
    return result;
}
val n = label(Direction.North);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "enum_def",
      "name": "Direction",
      "id": 0
    },
    {
      "ast": "fn_def",
      "name": "label",
      "is_pub": true,
      "params": [
        {
          "name": "d",
          "type": ""
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val result = case d {"
        },
        {
          "source": "return result;"
        }
      ]
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Direction"
          }
        ],
        "return_type": "string"
      },
      "return_type": "string"
    }
  ]
}
```

