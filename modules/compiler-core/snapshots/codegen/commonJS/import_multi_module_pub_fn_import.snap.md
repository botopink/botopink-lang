----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- JAVASCRIPT -- math.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

function double(x) {
    return __bp_int((x * 2), -2147483648, 2147483647, "* on i32 at math.bp:2:14");
}
exports.double = double;
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
const { double } = require("./math.js");

const result = double(21);
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { double } from "./math";



```

----- RUN LOG -----
```logs
```
