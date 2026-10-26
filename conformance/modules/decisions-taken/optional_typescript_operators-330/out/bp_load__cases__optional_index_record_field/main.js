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

//// Decision 330 — `xs?.[i]` over an optional array of records answers the

//// record, or nothing: a field read off it by `?.` or `!` finds the record's

//// own slot, even when another record declares a field of the same name.

class Field {
    constructor(name, message) {
        this.name = name;
        this.message = message;
    }
}
Field.prototype.__bp = "Field";

class Label {
    constructor(name, id) {
        this.name = name;
        this.id = id;
    }
}
Label.prototype.__bp = "Label";

function fields(k) {
    if ((k === 0)) { return null; }
    return [new Field("email", null)];
}

function main() {
    const some = fields(1);
    const first = (() => { const __bp_opt_18_21 = some; if (__bp_opt_18_21 != null) { return __bp_array_at(__bp_opt_18_21, 0); } else { return null; } })();
    __bp_print((() => { const __bp_nullish = first?.name; if (__bp_nullish != null) { return __bp_nullish; } else { return "no field"; } })());
    __bp_print((() => { const __bp_opt_20_16 = first; if (__bp_opt_20_16 != null) { return __bp_opt_20_16; } else { return (() => { throw Object.defineProperty(new Error("value is null — first! at src/main.bp:20:11"), '__bp_panic', { value: true }) })(); } })().name);
    __bp_print((() => { const __bp_nullish = first?.message; if (__bp_nullish != null) { return __bp_nullish; } else { return "no message"; } })());
    const none = fields(0);
    const missing = (() => { const __bp_opt_23_23 = none; if (__bp_opt_23_23 != null) { return __bp_array_at(__bp_opt_23_23, 0); } else { return null; } })();
    __bp_print((() => { const __bp_nullish = missing?.name; if (__bp_nullish != null) { return __bp_nullish; } else { return "no field"; } })());
    __bp_print(new Label("tag", 1).name);
}
exports.main = main;

function __bp_loaded_main() {
    main();
    return ({ ok: null });
}
exports.__bp_loaded_main = __bp_loaded_main;

function __bp_loaded_main_off() {
    return ({ error: "" });
}
exports.__bp_loaded_main_off = __bp_loaded_main_off;

function __bp_loaded_info() {
    return "cases/optional_index_record_field|*";
}
exports.__bp_loaded_info = __bp_loaded_info;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { Field, Label, fields, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
