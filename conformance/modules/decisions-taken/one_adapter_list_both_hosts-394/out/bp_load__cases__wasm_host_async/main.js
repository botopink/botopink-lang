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

//// Front 140 step 5 (decisions 392–394) — `Async` on wasm behaves as a Promise,

//// under wasmtime (`wasi`: `wasi:clocks/monotonic-clock` + `wasi:io/poll`) and

//// under node (`browser`: the loader's `setTimeout`, the JS event loop), and the

//// answers equal commonJS's and erlang's. `delay`, `race`, `raceOf` and

//// `spawnAll` are declared here with the bindings std carries on Node and the

//// BEAM and decision 393's adapters on wasm (std's own wasm bindings are

//// `02/97` step 17's). `raceOf` answers the first thunk to SETTLE: the block

//// that awaits 30 ms loses to the 10 ms delay (392 (1)); `race` over started

//// tasks answers the first to settle — element zero here too, since erlang's

//// eager tasks answer element zero; `spawnAll` keeps the order of the input.

//// Every line is printed from one task chain: the order of effects between

//// concurrent tasks is no target's contract (335 (2)).

function delay(millis, value) { return __bp_host_mark(() => ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(millis, value)); }

function race(tasks) { return __bp_host_mark(() => ((__fs) => __fs.length === 0 ? Promise.reject(new Error('async.race: empty task list')) : Promise.race(__fs))(tasks)); }

function raceOf(tasks) { return __bp_host_mark(() => ((__ts) => __ts.length === 0 ? Promise.reject(new Error('async.raceOf: empty task list')) : Promise.race(__ts.map((__f) => (__f)())))(tasks)); }

function spawnAll(tasks) { return __bp_host_mark(() => Promise.all((tasks).map((__f) => (__f)()))); }

async function run() {
    const first = await raceOf([() => {
    return (async () => {
        await delay(30, 0);
        "a";
    })();
}, () => {
    return delay(10, "b");
}]);
    __bp_print(("raceOf " + first));
    const r = await race([delay(5, "x"), delay(60, "y")]);
    __bp_print(("race " + r));
    const all = await spawnAll([() => {
    return delay(20, "one");
}, () => {
    return delay(5, "two");
}, () => {
    return delay(1, "three");
}]);
    __bp_print(("spawnAll " + all.join(",")));
    const n = await delay(0, 7);
    __bp_print(__bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:68:13"));
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
    return "cases/wasm_host_async|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { delay, race, raceOf, spawnAll, run, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
