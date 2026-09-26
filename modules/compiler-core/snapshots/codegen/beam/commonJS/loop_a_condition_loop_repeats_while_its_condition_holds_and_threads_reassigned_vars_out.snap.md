----- SOURCE CODE -- main.bp
```botopink
fn count(limit: i32) -> i32 {
    var i = 0;
    var acc = "";
    while (i < limit) {
        acc = acc + i.toString();
        i = i + 1;
    };
    @print(acc);
    return i;
}
fn evens(limit: i32) -> i32 {
    var i = 0;
    var sum = 0;
    while (i < limit) {
        i = i + 1;
        if (i % 2 == 1) { continue; };
        sum = sum + i;
    };
    return sum;
}
fn main() {
    @print(count(4));
    @print(count(0));
    @print(evens(6));
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

function count(limit) {
    let i = 0;
    let acc = "";
    while ((i < limit)) {
    acc = (acc + i.toString());
    i = (i + 1);
}
    __bp_print(acc);
    return i;
}

function evens(limit) {
    let i = 0;
    let sum = 0;
    while ((i < limit)) {
    i = (i + 1);
    if (((i % 2) === 1)) { continue; }
    sum = (sum + i);
}
    return sum;
}

function main() {
    __bp_print(count(4));
    __bp_print(count(0));
    __bp_print(evens(6));
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
0123
4

0
12
```
