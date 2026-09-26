----- SOURCE CODE -- main.bp
```botopink
fn pick(xs: Array<string>) -> string {
    var first = "";
    var last = "";
    var i = 0;
    for (xs) { x ->
        if (i == 0) { first = x; };
        last = x;
        i = i + 1;
    };
    return first + "-" + last;
}
fn weigh(xs: Array<i32>) -> i32 {
    var total = 0;
    for (0..xs.length) { i ->
        total = total + (xs[i] ?? 0) * (i + 1);
    };
    return total;
}
fn main() {
    @print(pick(["a", "b", "c"]));
    @print(weigh([10, 20, 30]));
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

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

function pick(xs) {
    let first = "";
    let last = "";
    let i = 0;
    for (const x of xs) {
    (() => { if ((i === 0)) { return first = x; } })();
    last = x;
    i = (i + 1);
}
    return ((first + "-") + last);
}

function weigh(xs) {
    let total = 0;
    for (const i of Array.from({length: Math.max(0, (xs.length) - (0))}, (_, __i) => (0) + __i)) {
    total = (total + (((() => { const __bp_nullish = __bp_array_at(xs, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })()) * ((i + 1))));
}
    return total;
}

function main() {
    __bp_print(pick(["a", "b", "c"]));
    __bp_print(weigh([10, 20, 30]));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
a-c
140
```
