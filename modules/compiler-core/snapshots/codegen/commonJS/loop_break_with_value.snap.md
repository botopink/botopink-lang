----- SOURCE CODE -- main.bp
```botopink
fn find(arr: i32[]) -> i32[] {
    return loop (arr) { x ->
        if (x > 10) { break x; };
    };
}
fn main() {
    @print(find([5, 8, 15, 20]));
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

function find(arr) {
    return (() => {
        const _acc = [];
        for (const x of arr) {
            if ((x > 10)) { _acc.push(x); continue; }
        }
        return _acc;
    })();
}

function main() {
    __bp_print(find([5, 8, 15, 20]));
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
[15,20]
```
