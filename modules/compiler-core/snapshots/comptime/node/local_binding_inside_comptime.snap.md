----- SOURCE CODE -- main.bp
```botopink
val hash = comptime { break 6364 + 11; };
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
-module(comptime_45af6ab6cf9e497c).
-export([main/0]).
main() -> "[{\"id\":\"ct_0\",\"value\":6375}]".

```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val hash = comptime {
    break 6364 + 11;
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "hash",
      "return_type": "void"
    }
  ]
}
```

