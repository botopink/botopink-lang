----- SOURCE CODE -- main.bp
```botopink
fn half(n: i32) -> Result<i32, string> {
    if (n % 2 == 0) {
        return n / 2;
    }
    throw "odd";
}

fn twice(n: i32) -> i32 {
    return try {
        defer print("deferred");
        val a = try half(n);
        val b = try half(a);
        b
    } catch { e ->
        print("caught: " + e);
        -1
    };
}

fn unbound(n: i32) -> i32 {
    return try {
        try half(n)
    } catch {
        -99
    };
}

pub fn main() -> void {
    print(twice(8));
    print(twice(3));
    print(unbound(4));
    print(unbound(3));
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

function __bp_region_try(r) { if ("error" in r) { throw { __bp_region: r.error }; } return r.ok; }

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function half(n) {
    if ((__bp_int((n % 2), -2147483648, 2147483647, "% on i32 at main.bp:2:11") === 0)) { return ({ ok: __bp_int(Math.trunc((n / 2)), -2147483648, 2147483647, "/ on i32 at main.bp:3:18") }); }
    return ({ error: "odd" });
}

function twice(n) {
    return (() => { try {
                            return (() => {
        const _s = true;
        {
            try {
                const _try1 = half(n);
                if ("error" in _try1) throw ({ __bp_region: _try1.error });
                const a = _try1.ok;
                const _try2 = half(a);
                if ("error" in _try2) throw ({ __bp_region: _try2.error });
                const b = _try2.ok;
                return b;
            } finally {
                __bp_print("deferred");
            }
        }
    })();
                        } catch (_rg0) {
                            if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                            const e = _rg0.__bp_region;
                            return (() => {
                const _s = true;
                {
                    __bp_print(("caught: " + e));
                    return (-1);
                }
            })();
                        } })();
}

function unbound(n) {
    return (() => { try {
                            return (() => {
        const _s = true;
        {
            return __bp_region_try(half(n));
        }
    })();
                        } catch (_rg0) {
                            if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                            return (() => {
                const _s = true;
                {
                    return (-99);
                }
            })();
                        } })();
}

function main() {
    __bp_print(twice(8));
    __bp_print(twice(3));
    __bp_print(unbound(4));
    __bp_print(unbound(3));
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

Object.defineProperty(exports, "__bp_priv__", { value: { half, twice, unbound, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function main(): void;

```

----- RUN LOG -----
```logs
deferred
2
deferred
caught: odd
-1
2
-99
```
