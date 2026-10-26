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

function __bp_region_try(r) { if ("error" in r) { throw { __bp_region: r.error }; } return r.ok; }

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 595 (3), (5) — the handler converts the region's failure into the

//// function's: `catch throw …`, or a block with a binder whose `throw` is the

//// enclosing function's (the block is no lambda). Each region fails with one

//// error type (`string` here); the function answers its own (`ConfigError`).

class ConfigError {
    static Missing(key) {
        return new ConfigError$Missing(key);
    }

    toString() {
        return __bp_text(this);
    }
}
ConfigError.prototype.__bp = "ConfigError";
class ConfigError$Missing extends ConfigError {
    constructor(key) {
        super();
        this.key = key;
    }

    get $0() {
        return this.key;
    }
}
ConfigError$Missing.prototype.tag = "Missing";
class ConfigError$Invalid extends ConfigError {
}
ConfigError$Invalid.prototype.tag = "Invalid";
ConfigError.Invalid = new ConfigError$Invalid();

function lookup(key) {
    if ((key === "port")) { return ({ ok: 80 }); }
    if ((key === "offset")) { return ({ ok: 1 }); }
    return ({ error: key });
}

function sum(a, b) {
    try {
        return ({ ok: (() => { try {
                    return (() => {
        const _s = true;
        {
            return __bp_int((__bp_region_try(lookup(a)) + __bp_region_try(lookup(b))), -2147483648, 2147483647, "+ on i32 at src/main.bp:17:32");
        }
    })();
                } catch (_rg0) {
                    if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                    throw ({ __bp_try: ({ error: ConfigError.Invalid }) });
                } })() });
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}

function port(key) {
    try {
        const p = (() => { try {
                            return (() => {
        const _s = true;
        {
            return __bp_region_try(lookup(key));
        }
    })();
                        } catch (_rg0) {
                            if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                            const e = _rg0.__bp_region;
                            return (() => {
                const _s = true;
                {
                    throw ({ __bp_try: ({ error: ConfigError.Missing(e) }) });
                }
            })();
                        } })();
        return ({ ok: __bp_int((p + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:24:14") });
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}

function show(r) {
    return (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return v.toString();
        }
        if ("error" in _s) {
            const e = _s.error;
            return (() => {
        const _s = e;
        if (_s.tag === "Missing") {
            const { key } = _s;
            return ("missing " + key);
        }
        if (_s.tag === "Invalid") return "invalid";
        throw new Error("case_clause");
    })();
        }
        throw new Error("case_clause");
    })();
}

function main() {
    __bp_print(show(sum("port", "offset")));
    __bp_print(show(sum("port", "host")));
    __bp_print(show(port("port")));
    __bp_print(show(port("host")));
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
    return "cases/try_block_catch_rethrow|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { ConfigError, ConfigError$Missing, ConfigError$Invalid, lookup, sum, port, show, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
