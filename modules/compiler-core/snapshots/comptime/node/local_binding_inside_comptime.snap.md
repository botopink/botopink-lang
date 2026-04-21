----- SOURCE CODE -- main.bp
```botopink
val hash = comptime { break 6364 + 11; };
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: (6364 + 11) }
];
process.stdout.write(JSON.stringify(results));

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
      "return_type": "void"
    }
  ]
}
```

