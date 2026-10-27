----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type Shape { Circle(r: i32), Square(side: i32) }

type Person(name: string, age: i32)

fn parse(s: string) -> Result<i32, string> {
    if (s == "") throw "empty input";
    return s.length;
}

fn radius(s: Shape) -> i32 {
    val assert Circle(r) = s catch Shape.Circle(r: 0 - 1);
    return r;
}

fn describe(p: Person) -> string {
    val assert Person(n, a) = p;
    return n + "/" + a.toString();
}

fn size(s: string) -> i32 {
    val assert Ok(n) = parse(s);
    return n;
}

fn reason(s: string) -> string {
    val assert Error(message) = parse(s);
    return message;
}

fn older(p: Person) -> i32 {
    val assert Person(n, a) = p catch Person(name: "none", age: 0);
    return a + n.length;
}

pub fn main() -> void {
    print(radius(Shape.Circle(r: 3)));
    print(radius(Shape.Square(side: 2)));
    print(describe(Person(name: "ana", age: 30)));
    print(size("four"));
    print(reason(""));
    print(older(Person(name: "bo", age: 41)));
}
```

----- JAVASCRIPT -- main.js
```javascript
const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
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

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

class Shape {
    static Circle(r) {
        return new Shape$Circle(r);
    }

    static Square(side) {
        return new Shape$Square(side);
    }

    toString() {
        return __bp_text(this);
    }
}
Shape.prototype.__bp = "Shape";
class Shape$Circle extends Shape {
    constructor(r) {
        super();
        this.r = r;
    }
}
Shape$Circle.prototype.tag = "Circle";
class Shape$Square extends Shape {
    constructor(side) {
        super();
        this.side = side;
    }
}
Shape$Square.prototype.tag = "Square";

class Person {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }
}
Person.prototype.__bp = "Person";

function parse(s) {
    let s$sp = null;
    if ((s === "")) { return ({ error: "empty input" }); }
    return ({ ok: ((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length) });
}

function radius(s) {
    const _assert0 = (() => { const _match = s; if (_match.tag === "Circle") { return _match; } else { return Shape.Circle(__bp_int((0 - 1), -2147483648, 2147483647, "- on i32 at main.bp:13:54")); } })();
    const { r } = _assert0;
    return r;
}

function describe(p) {
    const _assert1 = (() => { const _match = p; if ((_match instanceof Person)) { return _match; } else { return (() => { throw Object.defineProperty(new Error("assert pattern did not match"), '__bp_panic', { value: true }) })(); } })();
    const { name: n, age: a } = _assert1;
    return ((n + "/") + a.toString());
}

function size(s) {
    const _assert2 = (() => { const _match = parse(s); if (("ok" in _match)) { return _match; } else { return (() => { throw Object.defineProperty(new Error("assert pattern did not match"), '__bp_panic', { value: true }) })(); } })();
    const n = _assert2.ok;
    return n;
}

function reason(s) {
    const _assert3 = (() => { const _match = parse(s); if (("error" in _match)) { return _match; } else { return (() => { throw Object.defineProperty(new Error("assert pattern did not match"), '__bp_panic', { value: true }) })(); } })();
    const message = _assert3.error;
    return message;
}

function older(p) {
    const _assert4 = (() => { const _match = p; if ((_match instanceof Person)) { return _match; } else { return new Person("none", 0); } })();
    const { name: n, age: a } = _assert4;
    return __bp_int((a + __bp_str_length(n)), -2147483648, 2147483647, "+ on i32 at main.bp:34:14");
}

function main() {
    __bp_print(radius(Shape.Circle(3)));
    __bp_print(radius(Shape.Square(2)));
    __bp_print(describe(new Person("ana", 30)));
    __bp_print(size("four"));
    __bp_print(reason(""));
    __bp_print(older(new Person("bo", 41)));
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

Object.defineProperty(exports, "__bp_priv__", { value: { Shape, Shape$Circle, Shape$Square, Person, parse, radius, describe, size, reason, older, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
















export declare function main(): void;

```

----- RUN LOG -----
```logs
3
-1
ana/30
4
empty input
43
```
