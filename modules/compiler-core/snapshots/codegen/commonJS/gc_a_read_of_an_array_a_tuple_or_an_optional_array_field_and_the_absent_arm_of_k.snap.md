----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type Field(name: string)

type Form(fields: ?Field[], tags: string[], range: #(i32, i32))

fn make(k: i32) -> ?Form {
    if (k == 0) return null;
    return Form(fields: [Field(name: "email")], tags: ["a", "b"], range: #(1, 2));
}

pub fn main() -> void {
    val f = make(1);
    val tags: string[] = f?.tags ?? [];
    print(tags.join(","));
    val none: string[] = make(0)?.tags ?? [];
    print(none.length);
    val r = f?.range ?? #(0, 0);
    print(r);
    print(f?.fields?.[0]?.name ?? "none");
    print(make(0)?.fields?.[0]?.name ?? "none");
    val empty: ?Form = Form(fields: null, tags: [], range: #(3, 4));
    print(empty?.fields?.[0]?.name ?? "none");
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

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

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Field {
    constructor(name) {
        this.name = name;
    }
}
Field.prototype.__bp = "Field";

class Form {
    constructor(fields, tags, range) {
        this.fields = fields;
        this.tags = tags;
        this.range = range;
    }
}
Form.prototype.__bp = "Form";
Form.prototype.__bp_s = { range: ["#", null, null] };

function make(k) {
    if ((k === 0)) { return null; }
    return new Form([new Field("email")], ["a", "b"], [1, 2]);
}

function main() {
    const f = make(1);
    const tags = (() => { const __bp_nullish = f?.tags; if (__bp_nullish != null) { return __bp_nullish; } else { return []; } })();
    __bp_print(tags.join(","));
    const none = (() => { const __bp_nullish = make(0)?.tags; if (__bp_nullish != null) { return __bp_nullish; } else { return []; } })();
    __bp_print(none.length);
    const r = (() => { const __bp_nullish = f?.range; if (__bp_nullish != null) { return __bp_nullish; } else { return [0, 0]; } })();
    __bp_print_as([["#", null, null]], r);
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_20_20 = f?.fields; if (__bp_opt_20_20 != null) { return __bp_array_at(__bp_opt_20_20, 0); } else { return null; } })()?.name; if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })());
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_21_26 = make(0)?.fields; if (__bp_opt_21_26 != null) { return __bp_array_at(__bp_opt_21_26, 0); } else { return null; } })()?.name; if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })());
    const empty = new Form(null, [], [3, 4]);
    __bp_print((() => { const __bp_nullish = (() => { const __bp_opt_23_24 = empty?.fields; if (__bp_opt_23_24 != null) { return __bp_array_at(__bp_opt_23_24, 0); } else { return null; } })()?.name; if (__bp_nullish != null) { return __bp_nullish; } else { return "none"; } })());
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

Object.defineProperty(exports, "__bp_priv__", { value: { Field, Form, make, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function main(): void;

```

----- RUN LOG -----
```logs
a,b
0
#(1, 2)
email
none
none
```
