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

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 595 (3) — `catch { e -> … }`: `e` is the region's error, a `case`

//// arm's binder typed by the region (656), matched with `case`. The block's

//// value is the fallback.

class HalfError {
    static Odd(value) {
        return new HalfError$Odd(value);
    }

    toString() {
        return __bp_text(this);
    }
}
HalfError.prototype.__bp = "HalfError";
class HalfError$Odd extends HalfError {
    constructor(value) {
        super();
        this.value = value;
    }

    get $0() {
        return this.value;
    }
}
HalfError$Odd.prototype.tag = "Odd";
class HalfError$Negative extends HalfError {
}
HalfError$Negative.prototype.tag = "Negative";
HalfError.Negative = new HalfError$Negative();

function half(n) {
    if ((n < 0)) { return ({ error: HalfError.Negative }); }
    if ((__bp_int((n % 2), -2147483648, 2147483647, "% on i32 at src/main.bp:11:11") !== 0)) { return ({ error: HalfError.Odd(n) }); }
    return ({ ok: __bp_int(Math.trunc((n / 2)), -2147483648, 2147483647, "/ on i32 at src/main.bp:12:14") });
}

function describe(n) {
    return (() => { try {
                            return (() => {
        const _s = true;
        {
            const _try1 = half(n);
            if ("error" in _try1) throw ({ __bp_region: _try1.error });
            const h = _try1.ok;
            const _try2 = half(h);
            if ("error" in _try2) throw ({ __bp_region: _try2.error });
            const q = _try2.ok;
            return ("quarter " + q.toString());
        }
    })();
                        } catch (_rg0) {
                            if (!(_rg0 !== null && typeof _rg0 === "object" && "__bp_region" in _rg0)) throw _rg0;
                            const e = _rg0.__bp_region;
                            return (() => {
                const _s = true;
                {
                    return (() => {
                        const _s = e;
                        if (_s.tag === "Odd") {
                            const { value } = _s;
                            return ("odd " + value.toString());
                        }
                        if (_s.tag === "Negative") return "negative";
                        throw new Error("case_clause");
                    })();
                }
            })();
                        } })();
}

function main() {
    __bp_print(describe(12));
    __bp_print(describe(6));
    __bp_print(describe((-4)));
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
    return "cases/try_block_catch_binder|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { HalfError, HalfError$Odd, HalfError$Negative, half, describe, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
