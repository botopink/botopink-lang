----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("erlang", "abs"),
  @External.Node("./stdlib.mjs", "abs")]
pub declare fn abs(n: i32) -> i32;

fn main() {
    @print(abs(-5));
}
```

----- JAVASCRIPT -- main.js
```javascript
const { abs } = require("./stdlib.mjs");
exports.abs = abs;

function main() {
    console.log(abs((-5)));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function abs(n: ): i32;



```

----- RUN LOG -----
```logs
```
