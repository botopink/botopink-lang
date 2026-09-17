----- SOURCE CODE -- main.bp
```botopink
val Direction = type {
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
    @print(result);
    return result;
}
val n = label(Direction.North);
fn main() {
    @print(n);
}
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
          "type": "Direction"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val result = case d {"
        },
        {
          "source": "@print(result);"
        },
        {
          "source": "return result;"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "n",
      "return_type": "string",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "Direction"
          }
        ],
        "return_type": "string"
      }
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "@print(n);"
        }
      ]
    }
  ]
}
```

