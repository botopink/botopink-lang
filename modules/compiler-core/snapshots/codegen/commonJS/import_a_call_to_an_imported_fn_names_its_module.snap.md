----- SOURCE CODE -- a.bp
```botopink
pub fn twice(x: i32) -> i32 {
    return x * 2;
}
```

----- JAVASCRIPT -- a.js
```javascript
function twice(x) {
    return (x * 2);
}
exports.twice = twice;
```

----- TYPESCRIPT TYPEDEF -- a.d.ts
```typescript
export declare function twice(x: i32): i32;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- b.bp
```botopink
import { twice };

pub fn quad(x: i32) -> i32 {
    return twice(twice(x));
}

pub fn main() {
    @print(quad(3));
}
```

----- JAVASCRIPT -- b.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(",")) + (t ? ")" : "]"));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

const { twice } = require("./module");

function quad(x) {
    return twice(twice(x));
}
exports.quad = quad;

function main() {
    __bp_print(quad(3));
}
exports.main = main;

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- b.d.ts
```typescript
import { twice } from "./module";


export declare function quad(x: i32): i32;


export declare function main(): void;

```

----- RUN LOG -----
```logs
```
