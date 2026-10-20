----- SOURCE CODE -- main.bp
```botopink
fn main() -> void {
    print("hello");
}

import {io.terminal.print} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "main",
      "is_pub": false,
      "params": [],
      "return_type": "void",
      "body": [
        {
          "source": "print(\"hello\");"
        }
      ]
    }
  ]
}
```

