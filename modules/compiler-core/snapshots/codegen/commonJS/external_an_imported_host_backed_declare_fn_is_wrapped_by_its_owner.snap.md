----- SOURCE CODE -- hostlib.bp
```botopink
#[compiler.external(.JavaScript("String($0)"), .Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))"""))]
pub declare fn hostKey(v: i32) -> string;

#[compiler.external(.JavaScript("$0.length"), .Erlang("erlang:length($0)"))]
pub declare fn hostLen(xs: array<string>) -> i32;

#[compiler.external(.JavaScript("console.log($0)"))]
pub declare fn nodeOnly(s: string) -> void;

import {compiler} from "std";
```

----- JAVASCRIPT -- hostlib.js
```javascript
function __bp_host_mark(f) {
    const m = (e) => { if (e != null && (e.__bp_panic != null || typeof e.__bp_assert_loc === "string" || e.__bp_host === true)) { return e; } const x = (e instanceof Error) ? e : new Error(String(e)); try { Object.defineProperty(x, "__bp_host", { value: true }); } catch (_) {} return x; };
    try {
        const r = f();
        return (r != null && typeof r.then === "function" && r.__bp_fails !== true) ? r.then((v) => v, (e) => { throw m(e); }) : r;
    } catch (e) {
        throw m(e);
    }
}

function hostKey(v) { return __bp_host_mark(() => String(v)); }
exports.hostKey = hostKey;

function hostLen(xs) { return __bp_host_mark(() => xs.length); }
exports.hostLen = hostLen;

function nodeOnly(s) { return __bp_host_mark(() => console.log(s)); }
exports.nodeOnly = nodeOnly;

Object.defineProperty(exports, "__bp_priv__", { value: { hostKey, hostLen, nodeOnly } });
```

----- TYPESCRIPT TYPEDEF -- hostlib.d.ts
```typescript
export declare function hostKey(v: number): string;


export declare function hostLen(xs: string[]): number;


export declare function nodeOnly(s: string): void;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import { hostlib.hostKey, hostlib.hostLen, hostlib.nodeOnly };

pub fn main() -> void {
    print(hostKey(42));
    print(hostLen(["a", "b"]));
}

import {io.terminal.print} from "std";
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

const { hostKey, hostLen, nodeOnly } = require("./test@hostlib");

function main() {
    __bp_print(hostKey(42));
    __bp_print(hostLen(["a", "b"]));
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

Object.defineProperty(exports, "__bp_priv__", { value: { hostKey, hostLen, nodeOnly, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { hostKey, hostLen, nodeOnly } from "./test@hostlib";






export declare function main(): void;

```

----- RUN LOG -----
```logs
42
2
```
