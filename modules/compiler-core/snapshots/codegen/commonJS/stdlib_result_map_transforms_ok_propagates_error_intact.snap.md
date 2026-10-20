----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
fn main() -> void {
    val r = parseAge("42").map({ n -> n + 1 });
}

import {failure.panic} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function parseAge(s) {
    (() => { throw Object.defineProperty(new Error("not implemented"), '__bp_panic', { value: true }) })();
}

function main() {
    const r = ((_r) => "error" in _r ? _r : { ok: ((n) => {
    return __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at main.bp:3:41");
})(_r.ok) })(parseAge("42"));
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { parseAge, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
