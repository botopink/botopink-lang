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

//// Decision 304 (144 B-13) — a behavior method declared `-> Result` dispatches

//// and wraps as a function does: called through a parameter typed by the

//// behavior, each implementation's `return v` is `Ok(v)`, its `throw e` is

//// `Error(e)` and its `try` propagates the error; a `default fn` of the

//// behavior that `try`s the dispatched method wraps the same.

// behavior KeyValueStore
//   fn get(...)
//   default fn getTwice(...)

class Memory {
    constructor(prefix) {
        this.prefix = prefix;
    }

    get(key) {
        if ((key === "")) { return ({ error: "empty key" }); }
        return ({ ok: (this.prefix + key) });
    }

    getTwice(key) {
        const _try0 = this.get(key);
        if ("error" in _try0) return _try0;
        const once = _try0.ok;
        return ({ ok: (once + once) });
    }
}
Memory.prototype.__bp = "Memory";
Memory.prototype["__bp_b_bp_load_cases_behavior_method_result_dispatch@main@@KeyValueStore"] = true;

class Layered {
    constructor(inner) {
        this.inner = inner;
    }

    get(key) {
        if ((key === "secret")) { return ({ error: "denied" }); }
        const _try1 = this.inner.get(key);
        if ("error" in _try1) return _try1;
        const found = _try1.ok;
        return ({ ok: (("[" + found) + "]") });
    }

    getTwice(key) {
        const _try2 = this.get(key);
        if ("error" in _try2) return _try2;
        const once = _try2.ok;
        return ({ ok: (once + once) });
    }
}
Layered.prototype.__bp = "Layered";
Layered.prototype["__bp_b_bp_load_cases_behavior_method_result_dispatch@main@@KeyValueStore"] = true;

function describe(r) {
    return (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return ("ok " + v);
        }
        if ("error" in _s) {
            const e = _s.error;
            return ("error " + e);
        }
        throw new Error("case_clause");
    })();
}

function read(store, key) {
    return describe(store.get(key));
}

function readTwice(store, key) {
    return describe(store.getTwice(key));
}

function main() {
    const memory = new Memory("m:");
    const layered = new Layered(memory);
    __bp_print(read(memory, "a"));
    __bp_print(read(memory, ""));
    __bp_print(read(layered, "b"));
    __bp_print(read(layered, ""));
    __bp_print(read(layered, "secret"));
    __bp_print(readTwice(memory, "c"));
    __bp_print(readTwice(layered, ""));
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
    return "cases/behavior_method_result_dispatch|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { Memory, Layered, describe, read, readTwice, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
