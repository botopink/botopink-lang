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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 207 — a parameter's type written inline: `props: type(href:

//// string, label: string, external: bool = false)`, the field grammar of

//// `type Name(…)` with no name. The call builds the value from its own

//// labelled arguments, each naming a field of the inline type (in any order,

//// a defaulted field left out); a value already of the type is passed as the

//// parameter itself; another parameter of the function stays an ordinary one.

class BpInline__link__props {
    constructor(href, label, external) {
        this.href = href;
        this.label = label;
        this.external = external;
    }
}
BpInline__link__props.prototype.__bp = "BpInline__link__props";
exports.BpInline__link__props = BpInline__link__props;

function link(props) {
    const mark = (() => { if (props.external) { return " (external)"; } else { return ""; } })();
    return ((((props.label + " <") + props.href) + ">") + mark);
}
exports.link = link;

class BpInline__again__props {
    constructor(href, label, external) {
        this.href = href;
        this.label = label;
        this.external = external;
    }
}
BpInline__again__props.prototype.__bp = "BpInline__again__props";

function again(props) {
    return link(new BpInline__link__props(props.href, props.label, false));
}

class BpInline__scaled__props {
    constructor(n, unit) {
        this.n = n;
        this.unit = unit;
    }
}
BpInline__scaled__props.prototype.__bp = "BpInline__scaled__props";

function scaled(props, times) {
    return ((__bp_int((props.n * times), -2147483648, 2147483647, "* on i32 at src/main.bp:24:21")).toString() + props.unit);
}

function main() {
    __bp_print(link(new BpInline__link__props("/a", "A", false)));
    __bp_print(link(new BpInline__link__props("/b", "B", true)));
    __bp_print(again(new BpInline__again__props("/c", "C", true)));
    __bp_print(scaled(new BpInline__scaled__props(4, "px"), 3));
    __bp_print(scaled(new BpInline__scaled__props(5, "em"), 2));
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
    return "cases/inline_param_type|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { BpInline__link__props, link, BpInline__again__props, again, BpInline__scaled__props, scaled, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
