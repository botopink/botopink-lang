----- SOURCE CODE -- main.bp
```botopink
type UserError(msg: string)
fn fetchName() -> @Result<string, UserError> {
    throw UserError(msg: "name missing");
}
fn fetchAge() -> @Result<i32, UserError> {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    @print(name, age);
}
fn main() {
    loadUser();
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

class UserError {
    constructor(msg) {
        this.msg = msg;
    }
}
UserError.prototype.__bp = "UserError";

function fetchName() {
    return ({ error: new UserError("name missing") });
}

function fetchAge() {
    return ({ error: new UserError("age missing") });
}

function loadUser() {
    const _try0 = fetchName();
    const name = "error" in _try0 ? ("anonymous") : _try0.ok;
    const _try1 = fetchAge();
    const age = "error" in _try1 ? (0) : _try1.ok;
    __bp_print(name, age);
}

function main() {
    loadUser();
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
anonymous 0
```
