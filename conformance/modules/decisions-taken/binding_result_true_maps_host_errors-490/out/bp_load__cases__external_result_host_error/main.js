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

function __bp_host_fail(F, e) {
    const n = e instanceof Error;
    return { error: new F.HostError(n ? e.message : String(e), "host", n ? F.HostErrorName.Error : F.HostErrorName.Throw, (n && typeof e.stack === "string") ? e.stack : null) };
}

function __bp_task(p) {
    const t = p.then((r) => { if (r != null && "error" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; });
    t.__bp_fails = true;
    t.catch(() => {});
    return t;
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

function __bp_host_result(F, f) {
    try {
        return { ok: f() };
    } catch (e) {
        return __bp_host_fail(F, e);
    }
}

function __bp_host_result_task(F, f) {
    return __bp_task(new Promise((r) => r(f())).then((v) => ({ ok: v }), (e) => __bp_host_fail(F, e)));
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decisions 431 (2), 489, 490 — a binding that writes `result: true` answers

//// `Result<T, HostError>`: a value is `Ok(v)`, and every way the host fails is

//// `Error(HostError(message, "host", name, detail))`. On commonJS a sync

//// binding runs in a `try`/`catch` and a `Async` one's rejection is caught;

//// on erlang and beam the call runs in a `try … catch Class:Reason`, and a

//// host that answers `{error, R}` is an `Error` too. `name` is the same on

//// every target: a JavaScript `Error` and an erlang `error` raise are

//// `HostErrorName.Error`, any other thrown value and an erlang `throw` are

//// `HostErrorName.Throw`. `message` is the host's text: `e.message` (else

//// `String(e)`), the erlang reason by `~tp` — an atom here, so both read alike.

//// `detail`, the stack, is not printed: a backend may leave it empty.

//// 

//// wasm has no host that raises: a wasm binding is an opcode, a private fn

//// (`fn:`, where `result:` is refused, decision 491) or a WASI adapter, and

//// none of today's adapters fails. Each binding here is a private fn on wasm

//// that answers the value the other hosts answer.

const { HostError, HostErrorName } = require("../std/failure.js");

function double(n) { return __bp_host_result(require("../std/failure.js"), () => ((n >= 0) ? n * 2 : (() => { throw new Error("negative"); })())); }

function thrown(n) { return __bp_host_result(require("../std/failure.js"), () => ((n > 0) ? n : (() => { throw "refused"; })())); }

function answered(n) { return __bp_host_result(require("../std/failure.js"), () => ((n > 0) ? n + 1 : (() => { throw new Error("refused"); })())); }

function later(n) { return __bp_host_result_task(require("../std/failure.js"), () => ((n > 0) ? Promise.resolve(n * 3) : Promise.reject(new Error("late")))); }

function hostError(message, name) {
    return new HostError(message, "host", name, null);
}

function doubleBody(n) {
    if ((n < 0)) { return ({ error: hostError("negative", HostErrorName.Error) }); }
    return ({ ok: __bp_int((n * 2), -2147483648, 2147483647, "* on i32 at src/main.bp:54:14") });
}

function thrownBody(n) {
    if ((n <= 0)) { return ({ error: hostError("refused", HostErrorName.Throw) }); }
    return ({ ok: n });
}

function answeredBody(n) {
    if ((n <= 0)) { return ({ error: hostError("refused", HostErrorName.Error) }); }
    return ({ ok: __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:64:14") });
}

function laterBody(n) {
    return __bp_task((async () => {
        if ((n <= 0)) { return ({ error: hostError("late", HostErrorName.Error) }); }
        return ({ ok: __bp_int((n * 3), -2147483648, 2147483647, "* on i32 at src/main.bp:69:14") });
    })());
}

function show(r) {
    (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return __bp_print("ok", v);
        }
        if ("error" in _s) {
            const e = _s.error;
            return __bp_print("error", e.message, e.kind, e.name);
        }
        throw new Error("case_clause");
    })();
}

async function run() {
    show(double(21));
    show(double((-1)));
    show(thrown(5));
    show(thrown(0));
    show(answered(1));
    show(answered(0));
    show(await __bp_await(later(2)));
    show(await __bp_await(later(0)));
    const _try0 = double((-4));
    const a = "error" in _try0 ? (7) : _try0.ok;
    const _try1 = await __bp_await(later((-1)));
    const b = "error" in _try1 ? (100) : _try1.ok;
    __bp_print(__bp_int((a + b), -2147483648, 2147483647, "+ on i32 at src/main.bp:90:13"));
}

function main() {
    run();
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
    return "cases/external_result_host_error|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { HostError, HostErrorName, double, thrown, answered, later, hostError, doubleBody, thrownBody, answeredBody, laterBody, show, run, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
