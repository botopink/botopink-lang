----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> Result<i32, string> {
    panic("not implemented");
}
fn process() -> Result<i32, string> {
    val r = try fetch();
    return r;
}
val x = process();

import {failure.panic} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "fetch",
      "is_pub": false,
      "params": [],
      "return_type": "Result<i32,string>",
      "body": [
        {
          "source": "panic(\"not implemented\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "process",
      "is_pub": false,
      "params": [],
      "return_type": "Result<i32,string>",
      "body": [
        {
          "source": "val r = try fetch();"
        },
        {
          "source": "return r;"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "x",
      "return_type": "Result<i32,string>",
      "expr": {
        "ast": "call",
        "params": [],
        "return_type": "Result<i32,string>"
      }
    }
  ]
}
```

