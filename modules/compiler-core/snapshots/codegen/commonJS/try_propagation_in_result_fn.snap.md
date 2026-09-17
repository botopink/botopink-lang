----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn inner(should_fail: bool) -> @Result<i32, string> {
    if (should_fail) {
        throw "inner-fail";
    } else {
        return 7;
    }
}
#[@result]
fn outer(should_fail: bool) -> @Result<i32, string> {
    val v = try inner(should_fail);
    return v + 1;
}
fn main() {
    val r = try outer(false) catch -1;
    @print(r);
    val r2 = try outer(true) catch -1;
    @print(r2);
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

function inner(should_fail) {
    if (should_fail) { return ({ error: "inner-fail" }); } else { return ({ ok: 7 }); }
}

function outer(should_fail) {
    const _try0 = inner(should_fail);
    if ("error" in _try0) return _try0;
    const v = _try0.ok;
    return ({ ok: (v + 1) });
}

function main() {
    const _try0 = outer(false);
    const r = "error" in _try0 ? ((-1)) : _try0.ok;
    __bp_print(r);
    const _try1 = outer(true);
    const r2 = "error" in _try1 ? ((-1)) : _try1.ok;
    __bp_print(r2);
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
8
-1
```
