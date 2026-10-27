----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- JAVASCRIPT -- math.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function double(x) {
    return __bp_int((x * 2), -2147483648, 2147483647, "* on i32 at math.bp:2:14");
}
exports.double = double;

Object.defineProperty(exports, "__bp_priv__", { value: { double } });
```

----- TYPESCRIPT TYPEDEF -- math.d.ts
```typescript
export declare function double(x: number): number;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {math.double};
val result = double(21);
```

----- JAVASCRIPT -- main.js
```javascript
const { double } = require("./test@math");

const result = double(21);

Object.defineProperty(exports, "__bp_priv__", { value: { double, result } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { double } from "./test@math";



```

----- RUN LOG -----
```logs
```
