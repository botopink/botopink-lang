----- SOURCE CODE -- main.bp
```botopink
fn isString(x: ?string) -> x is string {
    if (x) { s -> return true; };
    return false;
}
fn main() -> void {
    print(isString("hello"));
    print(isString(null));
}

import {io.terminal.print} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "isString",
      "is_pub": false,
      "params": [
        {
          "name": "x",
          "type": "?string"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "if (x) { s -> return true; };"
        },
        {
          "source": "return false;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "print(isString(\"hello\"));"
        },
        {
          "source": "print(isString(null));"
        }
      ]
    }
  ]
}
```

