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

//// Decision 147 (lg-a) beside a generic constructor: a lambda argument of a

//// fallible field takes the expectation of a FRESH instance of the

//// constructor, so `Box(…)` answering `Box<?T>` in one method leaves the next

//// `Box(…)`, answering `Box<Array<T>>`, free.

class Box {
    constructor(run) {
        this.run = run;
    }

    optional() {
        const inner = this.run;
        return Object.defineProperty(new Box((at) => {
    return optionalOf(at, inner);
}), "__bp_s", { value: { $T: this.__bp_s?.$T } });
    }

    array() {
        const inner = this.run;
        return Object.defineProperty(new Box((at) => {
    return arrayOf(at, inner);
}), "__bp_s", { value: { $T: ["[", this.__bp_s?.$T] } });
    }
}
Box.prototype.__bp = "Box";
exports.Box = Box;

function present(v) {
    return __bp_array_at([v], 0);
}

function optionalOf(at, inner) {
    const _try0 = inner(at);
    if ("error" in _try0) return _try0;
    const v = _try0.ok;
    return ({ ok: present(v) });
}

function arrayOf(at, inner) {
    const _try0 = inner(at);
    if ("error" in _try0) return _try0;
    const v = _try0.ok;
    return ({ ok: [v, v] });
}

function shout(at) {
    if ((at === "")) { return ({ error: "empty" }); }
    return ({ ok: (at + "!") });
}

function main() {
    const box = new Box(shout);
    const many = box.array().run;
    __bp_print(((_r) => "error" in _r ? ([]) : _r.ok)(many("hi")).length);
    __bp_print(((_r) => "error" in _r)(many("")));
    const maybe = box.optional().run;
    __bp_print(((_r) => !("error" in _r))(maybe("yo")));
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
    return "cases/generic_ctor_fallible_lambda_fresh|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Box, present, optionalOf, arrayOf, shout, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
