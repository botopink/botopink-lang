----- SOURCE CODE -- main.bp
```botopink
fn parse() -> Result<i32, string> {
    return 42;
}
fn main() {
    val result = parse();
    val assert Ok(value) = result;
    print(value);
}

import {io.terminal.print} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "parse",
      "is_pub": false,
      "params": [],
      "return_type": "Result<i32,string>",
      "body": [
        {
          "source": "return 42;"
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
          "source": "val result = parse();"
        },
        {
          "source": "val assert Ok(value) = result;"
        },
        {
          "source": "print(value);"
        }
      ]
    }
  ]
}
```

