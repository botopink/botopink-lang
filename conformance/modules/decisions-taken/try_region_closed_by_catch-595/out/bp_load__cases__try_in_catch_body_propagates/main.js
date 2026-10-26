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

function __bp_try(r) { if ("error" in r) { throw { __bp_try: r }; } return r.ok; }

function __bp_region_try(r) { if ("error" in r) { throw { __bp_region: r.error }; } return r.ok; }

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 595 (6) — a `try` in the handler's body belongs to the enclosing

//// region or the function, never to its own `catch`: `backup`'s failure leaves

//// `load` as its `Error`, and in `either` it reaches the outer region's

//// `catch`.

function primary(n) {
    if ((n > 10)) { return ({ error: "primary down" }); }
    return ({ ok: n });
}

function backup(n) {
    if ((n > 20)) { return ({ error: "backup down" }); }
    return ({ ok: __bp_int((n * 100), -2147483648, 2147483647, "* on i32 at src/main.bp:15:14") });
}

function load(n) {
    try {
        const v = (() => { try {
                            return (() => {
        const _s = true;
        {
            return __bp_region_try(primary(n));
        }
    })();
                        } catch (_rg0) {
                            if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                            return (() => {
                const _s = true;
                {
                    return __bp_try(backup(n));
                }
            })();
                        } })();
        return ({ ok: __bp_int((v + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:20:14") });
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}

function either(n) {
    return (() => { try {
                    return (() => {
        const _s = true;
        {
            return (() => { try {
                                    return (() => {
                const _s = true;
                {
                    return __bp_region_try(primary(n));
                }
            })();
                                } catch (_rg1) {
                                    if (!(_rg1 !== null && typeof _rg1 === "object" && "__bp_region" in _rg1)) throw _rg1;
                                    return (() => {
                        const _s = true;
                        {
                            return __bp_region_try(backup(n));
                        }
                    })();
                                } })();
        }
    })();
                } catch (_rg0) {
                    if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                    return (-1);
                } })();
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
            return e;
        }
        throw new Error("case_clause");
    })();
}

function main() {
    __bp_print(show(load(5)));
    __bp_print(show(load(15)));
    __bp_print(show(load(25)));
    __bp_print(either(5));
    __bp_print(either(15));
    __bp_print(either(25));
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
    return "cases/try_in_catch_body_propagates|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { primary, backup, load, either, show, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
