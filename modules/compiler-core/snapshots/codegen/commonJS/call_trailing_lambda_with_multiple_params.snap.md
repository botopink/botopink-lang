----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32, f: fn(i32, i32) -> i32) -> i32 {
    panic("not implemented");
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}

import {failure.panic} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
function calc(factor, f) {
    (() => { throw Object.defineProperty(new Error("not implemented"), '__bp_panic', { value: true }) })();
}

function main() {
    const r = calc(2, (a, b) => {
    return 0;
});
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { calc, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
