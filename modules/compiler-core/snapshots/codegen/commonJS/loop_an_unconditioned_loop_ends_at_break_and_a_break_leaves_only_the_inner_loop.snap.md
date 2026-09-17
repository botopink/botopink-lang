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
    loop (outer < 3) {
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

function firstSquareOver(n) {
    let k = 0;
    while (true) {
    k = (k + 1);
    if (((k * k) > n)) { break; }
}
    return k;
}

function nested() {
    let outer = 0;
    let inner = 0;
    while ((outer < 3)) {
    outer = (outer + 1);
    while (true) {
    inner = (inner + 1);
    break;
}
}
    return ((outer * 10) + inner);
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
