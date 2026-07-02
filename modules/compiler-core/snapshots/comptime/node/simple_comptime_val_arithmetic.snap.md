----- SOURCE CODE -- main.bp
```botopink
val x = comptime 10 + 5;
val y = comptime 42;
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
-module(comptime_321ce357ab06bd3c).
-export([main/0]).
main() -> "[{\"id\":\"ct_0\",\"value\":15},{\"id\":\"ct_1\",\"value\":42}]".

```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val x = 15;

val y = 42;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "x",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "y",
      "return_type": "i32"
    }
  ]
}
```

