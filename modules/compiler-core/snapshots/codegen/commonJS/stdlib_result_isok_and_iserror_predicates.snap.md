----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
fn main() {
    val r = parseAge("42");
    val ok = r.isOk();
    val bad = r.isError();
}

import {failure.panic} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
function parseAge(s) {
    (() => { throw Object.defineProperty(new Error("not implemented"), '__bp_panic', { value: true }) })();
}

function main() {
    const r = parseAge("42");
    const ok = ((_r) => !("error" in _r))(r);
    const bad = ((_r) => "error" in _r)(r);
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
