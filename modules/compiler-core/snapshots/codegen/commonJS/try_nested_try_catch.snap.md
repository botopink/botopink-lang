----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
#[@result]
fn inner() -> @Result<i32, DbError> {
    throw DbError(msg: "conn refused");
}
#[@result]
fn outer() -> @Result<i32, DbError> {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
fn main() {
    @print(process());
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

class DbError {
    constructor(msg) {
        this.msg = msg;
    }
}

function inner() {
    return ({ error: new DbError("conn refused") });
}

function outer() {
    return ({ error: new DbError("timeout") });
}

function process() {
    const _try0 = inner();
    const a = "error" in _try0 ? (0) : _try0.ok;
    const _try1 = outer();
    const b = "error" in _try1 ? (a) : _try1.ok;
    __bp_print(a, b);
    return (a + b);
}

function main() {
    __bp_print(process());
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
0 0
0
```
