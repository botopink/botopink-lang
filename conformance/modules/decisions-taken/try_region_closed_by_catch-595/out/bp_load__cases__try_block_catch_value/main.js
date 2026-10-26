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

function __bp_region_try(r) { if ("error" in r) { throw { __bp_region: r.error }; } return r.ok; }

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 595 (2), (3), (4) — `try { … } catch …` is a region: every `try`

//// written in the block hands its failure to the one `catch`, so a function

//// with no `Result` in its return runs fallible calls. The block's value is its

//// last expression written without `;`; the handler is the fallback — an

//// expression, or a block whose value is its last expression.

function half(n) {
    if ((__bp_int((n % 2), -2147483648, 2147483647, "% on i32 at src/main.bp:10:11") !== 0)) { return ({ error: "odd" }); }
    return ({ ok: __bp_int(Math.trunc((n / 2)), -2147483648, 2147483647, "/ on i32 at src/main.bp:11:14") });
}

function quarter(n) {
    return (() => { try {
                    return (() => {
        const _s = true;
        {
            const _try1 = half(n);
            if ("error" in _try1) throw ({ __bp_region: _try1.error });
            const h = _try1.ok;
            return __bp_region_try(half(h));
        }
    })();
                } catch (_rg0) {
                    if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                    return 0;
                } })();
}

function halves(a, b) {
    const total = (() => { try {
                            return (() => {
        const _s = true;
        {
            return __bp_int((__bp_region_try(half(a)) + __bp_region_try(half(b))), -2147483648, 2147483647, "+ on i32 at src/main.bp:22:35");
        }
    })();
                        } catch (_rg0) {
                            if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                            return (() => {
                const _s = true;
                {
                    __bp_print("not even");
                    return (-1);
                }
            })();
                        } })();
    return total;
}

function main() {
    __bp_print(quarter(8));
    __bp_print(quarter(6));
    __bp_print(halves(4, 6));
    __bp_print(halves(4, 5));
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
    return "cases/try_block_catch_value|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { half, quarter, halves, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
