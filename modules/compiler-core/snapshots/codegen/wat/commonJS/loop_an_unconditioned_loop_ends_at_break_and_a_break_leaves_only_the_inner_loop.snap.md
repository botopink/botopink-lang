----- SOURCE CODE -- main.bp
```botopink
fn firstSquareOver(n: i32) -> i32 {
    var k = 0;
    loop {
        k = k + 1;
        if (k * k > n) { break; };
    };
    return k;
}
fn nested() -> i32 {
    var outer = 0;
    var inner = 0;
    while (outer < 3) {
        outer = outer + 1;
        loop {
            inner = inner + 1;
            break;
        };
    };
    return outer * 10 + inner;
}
fn main() {
    @print(firstSquareOver(20));
    @print(nested());
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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

function firstSquareOver(n) {
    let k = 0;
    while (true) {
    k = __bp_int((k + 1), -2147483648, 2147483647, "+ on i32 at main.bp:4:15");
    if ((__bp_int((k * k), -2147483648, 2147483647, "* on i32 at main.bp:5:15") > n)) { break; }
}
    return k;
}

function nested() {
    let outer = 0;
    let inner = 0;
    while ((outer < 3)) {
    outer = __bp_int((outer + 1), -2147483648, 2147483647, "+ on i32 at main.bp:13:23");
    while (true) {
    inner = __bp_int((inner + 1), -2147483648, 2147483647, "+ on i32 at main.bp:15:27");
    break;
}
}
    return __bp_int((__bp_int((outer * 10), -2147483648, 2147483647, "* on i32 at main.bp:19:18") + inner), -2147483648, 2147483647, "+ on i32 at main.bp:19:23");
}

function main() {
    __bp_print(firstSquareOver(20));
    __bp_print(nested());
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
5
33
```
