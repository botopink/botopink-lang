----- SOURCE CODE -- models/user.bp
```botopink
pub fn label() -> string {
    return "models/user";
}
```

----- JAVASCRIPT -- models/user.js
```javascript
function label() {
    return "models/user";
}
exports.label = label;
```

----- TYPESCRIPT TYPEDEF -- models/user.d.ts
```typescript
export declare function label(): string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- services/user.bp
```botopink
pub fn tag() -> string {
    return "services/user";
}
```

----- JAVASCRIPT -- services/user.js
```javascript
function tag() {
    return "services/user";
}
exports.tag = tag;
```

----- TYPESCRIPT TYPEDEF -- services/user.d.ts
```typescript
export declare function tag(): string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {label} from "models/user";
import {tag} from "services/user";

fn main() {
    @print(label());
    @print(tag());
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

const { label } = require("./models/user.js");

const { tag } = require("./services/user.js");

function main() {
    __bp_print(label());
    __bp_print(tag());
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { label } from "./models/user";


import { tag } from "./services/user";



```

----- RUN LOG -----
```logs
models/user
services/user
```
