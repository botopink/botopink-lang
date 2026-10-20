----- SOURCE CODE -- main.bp
```botopink
pub fn main() -> void {
    val b = Bytes.fromUtf8("hello");
    print(b.length());
    print(b.slice(1, 3).length());
    val c = b.concat(Bytes.fromUtf8("!"));
    print(c.length());
    print(b == Bytes.fromUtf8("hello"));
    val r = b.toUtf8();
    print(r);
    val parts = "a,b,c".split(",");
    print(parts);
    print("hello".at(1));
    print("hello".at(9));
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

// behavior Bytes
//   fn fromUtf8(...)
//   fn toUtf8(...)
//   fn length(...)
//   fn concat(...)
//   default fn slice(...)
Uint8Array.prototype.toUtf8 = function() { return ((__b) => require('buffer').isUtf8(__b) ? { ok: new TextDecoder("utf-8", { ignoreBOM: true }).decode(__b) } : { error: "Bytes.toUtf8: not valid UTF-8" })(this); };
Uint8Array.prototype.concat = function(other) { return ((__a, __b) => { const __r = new Uint8Array(__a.length + __b.length); __r.set(__a, 0); __r.set(__b, __a.length); return __r; })(this, other); };
Uint8Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__b, __a, __e) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return new Uint8Array(__b.subarray(__s, Math.max(__s, __f))); })(this, start, end); } else { return ((__b, __a) => { if (__a == null) __a = 0; const __n = __b.length; const __s = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return new Uint8Array(__b.subarray(__s, __n)); })(this, start); }
};

function main() {
    const b = (new TextEncoder().encode("hello"));
    __bp_print(b.length);
    __bp_print(b.slice(1, 3).length);
    const c = b.concat((new TextEncoder().encode("!")));
    __bp_print(c.length);
    __bp_print(__bp_eq(b, (new TextEncoder().encode("hello")), 0));
    const r = b.toUtf8();
    __bp_print(r);
    const parts = "a,b,c".split(",");
    __bp_print(parts);
    __bp_print(("hello".at(1) ?? null));
    __bp_print(("hello".at(9) ?? null));
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function main(): void;

```

----- RUN LOG -----
```logs
5
2
6
true
Ok("hello")
["a", "b", "c"]
e
null
```
