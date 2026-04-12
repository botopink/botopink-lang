----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- JAVASCRIPT -- math.js
```javascript
function double(x) {
    return (x * 2);
}
exports.double = double;
```

----- TYPESCRIPT TYPEDEF -- math.d.ts
```typescript
export declare function double(x: i32): i32;

```

----- SOURCE CODE -- main.bp
```botopink
use {double} from "math";
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
