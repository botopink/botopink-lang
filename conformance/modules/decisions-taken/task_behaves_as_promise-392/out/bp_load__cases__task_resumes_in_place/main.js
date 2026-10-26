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

function __bp_task(p) {
    const t = p.then((r) => { if (r != null && "error" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; });
    t.__bp_fails = true;
    t.catch(() => {});
    return t;
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

function __bp_host_mark(f) {
    const m = (e) => { if (e != null && (e.__bp_panic != null || typeof e.__bp_assert_loc === "string" || e.__bp_host === true)) { return e; } const x = (e instanceof Error) ? e : new Error(String(e)); try { Object.defineProperty(x, "__bp_host", { value: true }); } catch (_) {} return x; };
    try {
        const r = f();
        return (r != null && typeof r.then === "function" && r.__bp_fails !== true) ? r.then((v) => v, (e) => { throw m(e); }) : r;
    } catch (e) {
        throw m(e);
    }
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

//// Decision 392 (2) — on wasm an asynchronous function is a resumable state

//// machine: its locals live in a frame across each `await`, and loops, `if`

//// arms, `try`, `try … catch`, a `case` after an `await`, a method answering

//// `Async`, a generic function and an `async { }` block that suspend (on a

//// real timer) are resumed where they stopped. The answers equal commonJS's,

//// erlang's and beam's.

function delay(millis, value) { return __bp_host_mark(() => ((__ms, __v) => new Promise((__r) => setTimeout(() => __r(__v), __ms)))(millis, value)); }

class Counter {
    constructor(base) {
        this.base = base;
    }

    async bump(by) {
        const step = await delay(1, by);
        return __bp_int((this.base + step), -2147483648, 2147483647, "+ on i32 at src/main.bp:20:26");
    }
}
Counter.prototype.__bp = "Counter";

function check(n) {
    return __bp_task((async () => {
        const v = await delay(1, n);
        if ((v < 0)) { return ({ error: ("negative " + v.toString()) }); }
        return ({ ok: __bp_int((v * 10), -2147483648, 2147483647, "* on i32 at src/main.bp:27:14") });
    })());
}

async function sumTo(xs, f, __bp_ty_T) {
    let total = 0;
    for (const x of xs) {
    const got = await f(x);
    total = __bp_int((total + got), -2147483648, 2147483647, "+ on i32 at src/main.bp:34:23");
}
    return total;
}

async function classify(n) {
    if ((n === 1)) { const w = await delay(2, "one"); return (w + "!"); }
    const label = (() => {
        const _s = n;
        if (_s === 0) return "zero";
        return "many";
    })();
    return label;
}

async function loopy() {
    let out = "";
    let i = 0;
    while ((i < 3)) {
    const c = await delay(1, i);
    out = (out + c.toString());
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:57:15");
}
    for (const k of Array.from({length: Math.max(0, (2) - (0))}, (_, __i) => (0) + __i)) {
    await (async () => { if ((k === 1)) { const s = await delay(1, "k"); return out = (out + s); } else { return out = (out + "-"); } })();
}
    return out;
}

function fallible() {
    return __bp_task((async () => {
        const _try0 = await __bp_await(check(2));
        if ("error" in _try0) return _try0;
        const a = _try0.ok;
        const _try1 = await __bp_await(check((-3)));
        if ("error" in _try1) return _try1;
        const b = _try1.ok;
        return ({ ok: (("unreachable " + a.toString()) + b.toString()) });
    })());
}

async function recovered() {
    const _try0 = await __bp_await(check((-1)));
    const r = "error" in _try0 ? (7) : _try0.ok;
    return r;
}

function show(r) {
    (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return __bp_print(("ok " + v));
        }
        if ("error" in _s) {
            const e = _s.error;
            return __bp_print(("error " + e));
        }
        throw new Error("case_clause");
    })();
}

async function run() {
    const c = new Counter(40);
    __bp_print(await c.bump(2));
    const checked = await __bp_await(check(4));
    (() => {
        const _s = checked;
        if ("ok" in _s) {
            const v = _s.ok;
            return __bp_print(("ok " + v.toString()));
        }
        if ("error" in _s) {
            const e = _s.error;
            return __bp_print(("error " + e));
        }
        throw new Error("case_clause");
    })();
    show(await __bp_await(fallible()));
    __bp_print(await recovered());
    __bp_print(await sumTo([1, 2, 3], (x) => {
    return delay(1, __bp_int((x * 2), -2147483648, 2147483647, "* on i32 at src/main.bp:96:52"));
}));
    __bp_print(await classify(0));
    __bp_print(await classify(1));
    __bp_print(await classify(5));
    __bp_print(await loopy());
    const t = (async () => {
        const x = await delay(3, 5);
        return __bp_int((x + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:103:18");
    })();
    __bp_print(await t);
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
    return "cases/task_resumes_in_place|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { delay, Counter, check, sumTo, classify, loopy, fallible, recovered, show, run, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
