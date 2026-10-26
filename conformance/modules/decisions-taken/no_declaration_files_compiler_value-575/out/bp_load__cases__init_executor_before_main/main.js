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

//// Decision 575 (3) — `compiler.init(executor)`: run-time code a decorator

//// compiles beside the annotated declaration, run once before `main` in the

//// program's init list — declarations in source order, the calls of one body

//// in order, any number per declaration. The executor is a tree (575 (4)):

//// the `comptime` parameter `label` and the body's `val name` are spliced as

//// literals. An executor may be named instead of written at the call: a

//// function of the decorator's module (`hello`), or a `syntax` parameter

//// (`run`), spliced as the annotation wrote it.

function hello() {
    __bp_print("hello");
}
exports.hello = hello;

function greet() {
    __bp_print("greet");
}
exports.greet = greet;

function home() {
    return "home";
}
exports.home = home;

function __bp_executor_0() {
    __bp_print(((("page") + " ") + ("home")));
}
exports.__bp_executor_0 = __bp_executor_0;

const __bp_init_0 = __bp_executor_0();

exports.__bp_init_0 = __bp_init_0;

function __bp_executor_1() {
    __bp_print(("again " + ("home")));
}
exports.__bp_executor_1 = __bp_executor_1;

const __bp_init_1 = __bp_executor_1();

exports.__bp_init_1 = __bp_init_1;

class Shell {
    constructor(title) {
        this.title = title;
    }
}
Shell.prototype.__bp = "Shell";
exports.Shell = Shell;

function __bp_executor_2() {
    __bp_print(((("layout") + " ") + ("Shell")));
}
exports.__bp_executor_2 = __bp_executor_2;

const __bp_init_2 = __bp_executor_2();

exports.__bp_init_2 = __bp_init_2;

function __bp_executor_3() {
    __bp_print(("again " + ("Shell")));
}
exports.__bp_executor_3 = __bp_executor_3;

const __bp_init_3 = __bp_executor_3();

exports.__bp_init_3 = __bp_init_3;

function __bp_executor_4() {
    __bp_print(((("view") + " ") + ("Shell")));
}
exports.__bp_executor_4 = __bp_executor_4;

const __bp_init_4 = __bp_executor_4();

exports.__bp_init_4 = __bp_init_4;

function __bp_executor_5() {
    __bp_print(("again " + ("Shell")));
}
exports.__bp_executor_5 = __bp_executor_5;

const __bp_init_5 = __bp_executor_5();

exports.__bp_init_5 = __bp_init_5;

const banner = "banner";

exports.banner = banner;

function __bp_executor_6() {
    hello();
}
exports.__bp_executor_6 = __bp_executor_6;

const __bp_init_6 = __bp_executor_6();

exports.__bp_init_6 = __bp_init_6;

function __bp_executor_7() {
    greet();
}
exports.__bp_executor_7 = __bp_executor_7;

const __bp_init_7 = __bp_executor_7();

exports.__bp_init_7 = __bp_init_7;

function main() {
    __bp_print("main");
    __bp_print(home());
    __bp_print(new Shell("t").title);
    __bp_print(banner);
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
    return "cases/init_executor_before_main|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { hello, greet, home, __bp_executor_0, __bp_init_0, __bp_executor_1, __bp_init_1, Shell, __bp_executor_2, __bp_init_2, __bp_executor_3, __bp_init_3, __bp_executor_4, __bp_init_4, __bp_executor_5, __bp_init_5, banner, __bp_executor_6, __bp_init_6, __bp_executor_7, __bp_init_7, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
