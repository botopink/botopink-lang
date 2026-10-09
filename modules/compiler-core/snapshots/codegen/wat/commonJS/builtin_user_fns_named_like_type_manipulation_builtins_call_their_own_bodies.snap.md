----- SOURCE CODE -- main.bp
```botopink
fn pick(n: i32) -> i32 { return n + 1; }
fn omit(n: i32) -> i32 { return n + 2; }
fn partial(n: i32) -> i32 { return n + 3; }
fn mergeRecords(a: i32, b: i32) -> i32 { return a + b; }
fn mapFields(n: i32) -> i32 { return n * 2; }
fn main() {
    @print(pick(1));
    @print(omit(1));
    @print(partial(1));
    @print(mergeRecords(2, 3));
    @print(mapFields(3));
}
```

----- JAVASCRIPT -- main.js
```javascript
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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

function pick(n) {
    return __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at main.bp:1:35");
}

function omit(n) {
    return __bp_int((n + 2), -2147483648, 2147483647, "+ on i32 at main.bp:2:35");
}

function partial(n) {
    return __bp_int((n + 3), -2147483648, 2147483647, "+ on i32 at main.bp:3:38");
}

function mergeRecords(a, b) {
    return __bp_int((a + b), -2147483648, 2147483647, "+ on i32 at main.bp:4:51");
}

function mapFields(n) {
    return __bp_int((n * 2), -2147483648, 2147483647, "* on i32 at main.bp:5:40");
}

function main() {
    __bp_print(pick(1));
    __bp_print(omit(1));
    __bp_print(partial(1));
    __bp_print(mergeRecords(2, 3));
    __bp_print(mapFields(3));
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
2
3
4
5
6
```
