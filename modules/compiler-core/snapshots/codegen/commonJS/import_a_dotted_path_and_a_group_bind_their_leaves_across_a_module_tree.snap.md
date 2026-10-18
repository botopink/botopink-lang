----- SOURCE CODE -- shapes/circle.bp
```botopink
pub fn name() -> string {
    return "circle";
}

pub fn label() -> string {
    return "shapes/circle";
}
```

----- JAVASCRIPT -- shapes/circle.js
```javascript
function name() {
    return "circle";
}
exports.name = name;

function label() {
    return "shapes/circle";
}
exports.label = label;

Object.defineProperty(exports, "__bp_priv__", { value: { name, label } });
```

----- TYPESCRIPT TYPEDEF -- shapes/circle.d.ts
```typescript
export declare function name(): string;


export declare function label(): string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- shapes/helpers.bp
```botopink
pub fn seven() -> i32 {
    return 7;
}

pub fn label() -> string {
    return "shapes/helpers";
}
```

----- JAVASCRIPT -- shapes/helpers.js
```javascript
function seven() {
    return 7;
}
exports.seven = seven;

function label() {
    return "shapes/helpers";
}
exports.label = label;

Object.defineProperty(exports, "__bp_priv__", { value: { seven, label } });
```

----- TYPESCRIPT TYPEDEF -- shapes/helpers.d.ts
```typescript
export declare function seven(): number;


export declare function label(): string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {shapes.circle.name as circleName, shapes: {helpers: {seven, label}, circle: {label as circleLabel}}};

fn main() {
    print(circleName());
    print(seven());
    print(label());
    print(circleLabel());
}

import {io.terminal.print} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
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

const { name: circleName, label: circleLabel } = require("./shapes/circle.js");
const { seven, label } = require("./shapes/helpers.js");

function main() {
    __bp_print(circleName());
    __bp_print(seven());
    __bp_print(label());
    __bp_print(circleLabel());
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { circleName, circleLabel, seven, label, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { name as circleName, label as circleLabel } from "./shapes/circle";
import { seven, label } from "./shapes/helpers";









```

----- RUN LOG -----
```logs
circle
7
shapes/helpers
shapes/circle
```
