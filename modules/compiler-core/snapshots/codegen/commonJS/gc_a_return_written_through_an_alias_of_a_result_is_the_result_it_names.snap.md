----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type ParseError { Empty }

pub type Parser<T> = Result<T, ParseError>;

pub type Checked<T> = Result<T, string>;

fn parsePort(s: string) -> Result<i32, ParseError> {
    if (s == "") throw ParseError.Empty;
    return 8080;
}

fn port(s: string) -> Parser<i32> {
    return parsePort(s);
}

fn check(n: i32) -> Result<i32, string> {
    if (n < 0) throw "negative";
    return n;
}

fn pass(r: Checked<i32>) -> Checked<i32> {
    return r;
}

pub fn main() -> void {
    print(try port("x") catch 0);
    print(try port("") catch 7);
    print(pass(check(4)).unwrapOr(0));
    print(pass(check(-4)).unwrapOr(0));
    print(pass(check(-1)).isError());
}
```

----- JAVASCRIPT -- main.js
```javascript
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

class ParseError {
    toString() {
        return __bp_text(this);
    }
}
ParseError.prototype.__bp = "ParseError";
class ParseError$Empty extends ParseError {
}
ParseError$Empty.prototype.tag = "Empty";
ParseError.Empty = new ParseError$Empty();

function parsePort(s) {
    if ((s === "")) { return ({ error: ParseError.Empty }); }
    return ({ ok: 8080 });
}

function port(s) {
    return parsePort(s);
}

function check(n) {
    if ((n < 0)) { return ({ error: "negative" }); }
    return ({ ok: n });
}

function pass(r) {
    return r;
}

function main() {
    __bp_print((() => { const _try0 = port("x"); if ("error" in _try0) { return (0); } return _try0.ok; })());
    __bp_print((() => { const _try1 = port(""); if ("error" in _try1) { return (7); } return _try1.ok; })());
    __bp_print(((_r) => "error" in _r ? (0) : _r.ok)(pass(check(4))));
    __bp_print(((_r) => "error" in _r ? (0) : _r.ok)(pass(check((-4)))));
    __bp_print(((_r) => "error" in _r)(pass(check((-1)))));
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

Object.defineProperty(exports, "__bp_priv__", { value: { ParseError, ParseError$Empty, parsePort, port, check, pass, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript


export declare type Parser<T> = { ok: T } | { error: ParseError };


export declare type Checked<T> = { ok: T } | { error: string };










export declare function main(): void;


declare class ParseError {
    readonly tag: "Empty";
    static readonly Empty: ParseError;
}


export {};

```

----- RUN LOG -----
```logs
8080
7
4
0
true
```
