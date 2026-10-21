----- SOURCE CODE -- main.bp
```botopink
val info = comptime compiler.typeInfo(void);

import {compiler} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "ident": "info",
      "return_type": "TypeInfo<void>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "void"
          }
        ],
        "return_type": "TypeInfo<void>"
      }
    }
  ]
}
```

