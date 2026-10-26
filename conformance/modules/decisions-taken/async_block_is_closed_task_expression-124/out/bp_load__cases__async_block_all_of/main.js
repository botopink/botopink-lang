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

//// Decision 124 of 1.0.10-beta (front 24, § Cells "`async { }`", first line;

//// guide.md § 3.1) — `async { … }` creates a `Async` in ANY function: `launch`

//// is a plain function (it answers a record, not a wrapper), builds two blocks

//// and passes them to `async.allOf`. Each block's `try await` makes its value

//// `Result<string, string>`, so each block is `Async<Result<string, string>>`.

//// 

//// `allOf` is taken in the shape front 24 step E7 writes —

//// `allOf(Array<Async<Result<T, E>>>) -> Async<Result<Array<T>, E>>`, started

//// Tasks, stopping at the first error (the README's open point 3 leaves the

//// thunk shape of `01-std/02` open; the cell follows E7 and the guide).

//// Printed from inside `run`.

//// 

//// On every target: `std/async` binds on wasm's two hosts (144 B-25, decision

//// 334), so the blocks run there as state machines under both.

const async = require("../std/async.js");

class Batch {
    constructor(task) {
        this.task = task;
    }
}
Batch.prototype.__bp = "Batch";

function fetchUser(id) {
    return __bp_task((async () => {
        if ((id <= 0)) { return ({ error: (("user " + id.toString()) + " does not exist") }); }
        return ({ ok: ("user" + id.toString()) });
    })());
}

function launch(a, b) {
    const all = async.allOf([__bp_task((async () => {
        return await __bp_await(fetchUser(a));
    })()), __bp_task((async () => {
        return await __bp_await(fetchUser(b));
    })())]);
    return new Batch(all);
}

function show(r) {
    (() => {
        const _s = r;
        if ("ok" in _s) {
            const names = _s.ok;
            return __bp_print(("ok " + names.join(",")));
        }
        if ("error" in _s) {
            const e = _s.error;
            return __bp_print(("error " + e));
        }
        throw new Error("case_clause");
    })();
}

async function run() {
    const good = launch(1, 2);
    show(await __bp_await(good.task));
    const bad = launch(1, 0);
    show(await __bp_await(bad.task));
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
    return "cases/async_block_all_of|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { async, Batch, fetchUser, launch, show, run, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
