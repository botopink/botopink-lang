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
    @print(circleName());
    @print(seven());
    @print(label());
    @print(circleLabel());
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
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { seven, label } from "./shapes/helpers";


import { seven, label } from "./shapes/helpers";


import { seven, label } from "./shapes/helpers";


import { seven, label } from "./shapes/helpers";



```

----- RUN LOG -----
```logs
circle
7
shapes/helpers
shapes/circle
```
