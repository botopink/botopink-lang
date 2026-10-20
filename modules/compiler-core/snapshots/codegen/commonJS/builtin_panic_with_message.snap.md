----- SOURCE CODE -- main.bp
```botopink
fn fail() -> void {
    panic("something went wrong");
}

import {failure.panic} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
function fail() {
    (() => { throw Object.defineProperty(new Error("something went wrong"), '__bp_panic', { value: true }) })();
}

Object.defineProperty(exports, "__bp_priv__", { value: { fail } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
