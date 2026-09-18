----- SOURCE CODE -- main.bp
```botopink
pub fn max(a: i32, b: i32) -> i32 {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}
fn main() {
    @print(max(3, 7));
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

function max(a, b) {
    if ((a < b)) { return b; } else { return a; }
}
exports.max = max;

function main() {
    __bp_print(max(3, 7));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function max(a: number, b: number): number;



```

----- RUN LOG -----
```logs
7
```
