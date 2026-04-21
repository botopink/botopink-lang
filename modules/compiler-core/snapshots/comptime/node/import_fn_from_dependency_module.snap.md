----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- TYPED AST JSON -- math.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "double",
      "is_pub": true,
      "params": [
        {
          "name": "x",
          "type": ""
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return x * 2;"
        }
      ]
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
use {double} from "math";
val result = double(21);
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "i32"
          }
        ],
        "return_type": "i32"
      },
      "return_type": "i32"
    }
  ]
}
```

