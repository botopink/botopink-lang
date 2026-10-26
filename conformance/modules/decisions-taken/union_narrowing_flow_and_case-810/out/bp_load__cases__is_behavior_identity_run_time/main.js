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

//// Decision 810 (1) — at run time `is` tests a type's identity alone: a

//// record's, and a behavior's (a record's or an enum's type implements it) — the value's type implements it — and a

//// function type by its arity, on every target. A behavior type pattern

//// (`Shown<unknown> { k -> … }`) is the same test. erlang and beam answered

//// `false` for every behavior, commonJS named a class no module emits, wasm

//// refused the test.

// behavior Shown
//   fn shown(...)

class Tag {
    constructor(value) {
        this.value = value;
    }

    shown() {
        return this.value;
    }
}
Tag.prototype.__bp = "Tag";
Tag.prototype["__bp_b_bp_load_cases_is_behavior_identity_run_time@main@@Shown"] = true;

class Box {
    constructor(item) {
        this.item = item;
    }
}
Box.prototype.__bp = "Box";

class Mark {
    static Named(text) {
        return new Mark$Named(text);
    }

    static shown(self) {
        return "mark";
    }

    shown() {
        return Mark.shown(this);
    }

    toString() {
        return __bp_text(this);
    }
}
Mark.prototype.__bp = "Mark";
Mark.prototype["__bp_b_bp_load_cases_is_behavior_identity_run_time@main@@Shown"] = true;
class Mark$Plain extends Mark {
}
Mark$Plain.prototype.tag = "Plain";
class Mark$Named extends Mark {
    constructor(text) {
        super();
        this.text = text;
    }

    get $0() {
        return this.text;
    }
}
Mark$Named.prototype.tag = "Named";
Mark.Plain = new Mark$Plain();

function kind(v) {
    const a = (() => { if ((v != null && v["__bp_b_bp_load_cases_is_behavior_identity_run_time@main@@Shown"] === true)) { return "shown"; } else { return "-"; } })();
    const b = (() => { if (v instanceof Box) { return "box"; } else { return "-"; } })();
    const c = (() => { if (((_v) => (typeof _v === "function" && _v.length === 1))(v)) { return "fn"; } else { return "-"; } })();
    return ((((a + " ") + b) + " ") + c);
}

function label(v) {
    return (() => {
        const _s = v;
        {
            const __bp_case_40_9 = _s;
            return (() => { if ((__bp_case_40_9 != null && __bp_case_40_9["__bp_b_bp_load_cases_is_behavior_identity_run_time@main@@Shown"] === true)) { const k = __bp_case_40_9; return "shown"; } else { return (() => {
                const _s = __bp_case_40_9;
                if (_s instanceof Box) {
                    const b = _s;
                    return "box";
                }
                {
                    return "other";
                }
            })(); } })();
        }
    })();
}

function say(n) {
    return n.toString();
}

function main() {
    __bp_print(kind(new Tag(1)));
    __bp_print(kind(new Box(1)));
    __bp_print(kind(say));
    __bp_print(kind(3));
    __bp_print(kind(Mark.Plain), kind(Mark.Named("n")));
    __bp_print(label(new Tag("t")), label(new Box("b")), label(say));
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
    return "cases/is_behavior_identity_run_time|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Tag, Box, Mark, Mark$Plain, Mark$Named, kind, label, say, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
