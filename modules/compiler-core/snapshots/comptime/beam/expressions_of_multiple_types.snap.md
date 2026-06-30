----- SOURCE CODE -- main.bp
```botopink
val pi      = comptime 3.14 * 2.0;
val maxVal  = comptime 100 + 1;
val banner  = comptime "Hello, " + "World";
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
-module(comptime_a6b9abbfb4644982).
-export([main/0]).
main() -> "[{\"id\":\"ct_0\",\"value\":0},{\"id\":\"ct_1\",\"value\":101},{\"id\":\"ct_2\",\"value\":0}]".

```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
val pi = 0;

val maxVal = 101;

val banner = 0;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "pi",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "indent": "maxVal",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "banner",
      "return_type": "string"
    }
  ]
}
```

