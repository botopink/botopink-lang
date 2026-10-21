----- SOURCE CODE -- main.bp
```botopink
val info = comptime compiler.typeInfo(string);

import {compiler} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "info",
      "return_type": "TypeInfo<string>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "string"
          }
        ],
        "return_type": "TypeInfo<string>"
      }
    }
  ]
}
```

