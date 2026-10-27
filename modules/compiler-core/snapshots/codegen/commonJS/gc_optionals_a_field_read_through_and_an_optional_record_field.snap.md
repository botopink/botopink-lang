----- SOURCE CODE -- main.bp
```botopink
type User(name: string, age: i32, next: ?User)

fn nameOf(u: ?User) -> ?string {
    return u?.name;
}

fn ageOf(u: ?User) -> ?i32 {
    return u?.age;
}

pub fn main() -> void {
    val a = User(name: "ann", age: 3, next: null);
    val b = User(name: "bob", age: 4, next: a);
    print(nameOf(a));
    print(nameOf(null));
    print(ageOf(b));
    print(b.next?.name);
    print(a.next?.name);
    print(b.next?.age ?? 0);
    print(a == b);
    print(b.next == a);
}

import {io.terminal.print} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
}

function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "function")) return ("fn/" + (v.__bp_arity ?? v.length));
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
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

function __bp_eq_User(a, b) {
    if (a === b) return true;
    return a.name === b.name && a.age === b.age && __bp_eq_Opt_User(a.next, b.next);
}

function __bp_eq_Opt_User(a, b) {
    if (a === b) return true;
    if (a == null || b == null) return a == null && b == null;
    return __bp_eq_User(a, b);
}

class User {
    constructor(name, age, next) {
        this.name = name;
        this.age = age;
        this.next = next;
    }
}
User.prototype.__bp = "User";

function nameOf(u) {
    return u?.name;
}

function ageOf(u) {
    return u?.age;
}

function main() {
    const a = new User("ann", 3, null);
    const b = new User("bob", 4, a);
    __bp_print(nameOf(a));
    __bp_print(nameOf(null));
    __bp_print(ageOf(b));
    __bp_print(b.next?.name);
    __bp_print(a.next?.name);
    __bp_print((() => { const __bp_nullish = b.next?.age; if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })());
    __bp_print(__bp_eq_User(a, b));
    __bp_print(__bp_eq(b.next, a, 0));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { User, nameOf, ageOf, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function main(): void;

```

----- RUN LOG -----
```logs
ann
null
4
ann
null
3
false
true
```
