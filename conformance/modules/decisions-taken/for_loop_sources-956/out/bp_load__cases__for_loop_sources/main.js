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

function __bp_try(r) { if ("error" in r) { throw { __bp_try: r }; } return r.ok; }

function __bp_yield_step(r) { return r.done ? YieldStep.Done : YieldStep.Yield(r.value); }

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

class YieldStep {
    static Yield(value) {
        return new YieldStep$Yield(value);
    }

    toString() {
        return __bp_text(this);
    }
}
YieldStep.prototype.__bp = "YieldStep";
class YieldStep$Yield extends YieldStep {
    constructor(value) {
        super();
        this.value = value;
    }

    get $0() {
        return this.value;
    }
}
YieldStep$Yield.prototype.tag = "Yield";
class YieldStep$Done extends YieldStep {
}
YieldStep$Done.prototype.tag = "Done";
YieldStep.Done = new YieldStep$Done();

//// Decision 956 — the collection loop is 105's: the sources after `for`, the

//// body a block opening with one parameter per source. One source is written

//// bare or in parentheses, one loop either way; `for await` walks an

//// `AsyncIter`; a source may be `try r`, the `Ok` value walked and an `Error`

//// propagated. Several sources, in parentheses, walk together, one item of each

//// per round, ending with the shortest; an open range `0...` never ends the

//// loop and serves as the index. The body is a loop body: `break`, `continue`,

//// a label after the keyword, a `return` leaving the enclosing function.

function* tens() {
    yield 10;
    yield 20;
    yield 30;
}

async function* countdown(n) {
    let i = n;
    while ((i > 0)) {
    yield i;
    i = __bp_int((i - 1), -2147483648, 2147483647, "- on i32 at src/main.bp:22:15");
}
}

class Grid {
    constructor(cells) {
        this.cells = cells;
    }

    iter() {
        return (function*() {
            while (true) {
                for (const c of this.cells) {
    yield c;
}
                break;
            }
        }).call(this);
    }
}
Grid.prototype.__bp = "Grid";

function items(n) {
    if ((n < 0)) { return ({ error: "negative" }); }
    return ({ ok: [n, __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:36:18")] });
}

function sum(n) {
    try {
        let total = 0;
        for (const x of __bp_try(items(n))) {
    total = __bp_int((total + x), -2147483648, 2147483647, "+ on i32 at src/main.bp:42:23");
}
        return ({ ok: total });
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}

// `return` from the walk of three sources leaves the function.

function firstOver(names, limit) {
    while (true) {
    const __for49_5_v0 = names;
    const __for49_5_v1 = tens();
    const __for49_5_s1 = (function*() {
        while (true) {
            for (const __for49_5_i1 of __for49_5_v1) {
    yield __for49_5_i1;
}
            break;
        }
    }).call(this);
    let __for49_5_c2 = 0;
    for (const name of __for49_5_v0) {
    const _case0 = (() => {
        const _s = __bp_yield_step(__for49_5_s1.next());
        if (_s.tag === "Yield") {
            const { value: ten } = _s;
            const i = __for49_5_c2;
            __for49_5_c2 = __bp_int((__for49_5_c2 + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:49:26");
            if ((ten > limit)) { return ({ __bp_return: true, value: ((name + "@") + i.toString()) }); }
            return;
        }
        if (_s.tag === "Done") {
            return ({ __bp_break: true });
        }
        throw new Error("case_clause");
    })();
            if (_case0 && _case0.__bp_return) return _case0.value;
            if (_case0 && _case0.__bp_break) break;
            if (_case0 && _case0.__bp_continue) continue;
}
    break;
}
    return "none";
}

async function run() {
    for await (const x of countdown(2)) {
    __bp_print(("await bare " + x.toString()));
}
    for await (const x of countdown(1)) {
    __bp_print(("await parenthesised " + x.toString()));
}
}

function main() {
    const xs = [1, 2, 3];
    for (const x of xs) {
    __bp_print(("bare " + x.toString()));
}
    for (const x of xs) {
    __bp_print(("parenthesised " + x.toString()));
}
    for (const i of Array.from({length: Math.max(0, ((3) + 1) - (1))}, (_, __i) => (1) + __i)) {
    __bp_print(("range " + i.toString()));
}
    for (const t of tens()) {
    __bp_print(("iter " + t.toString()));
}
    const g = new Grid([4, 5]);
    let total = 0;
    for (const c of g.iter()) {
    total = __bp_int((total + c), -2147483648, 2147483647, "+ on i32 at src/main.bp:81:23");
}
    __bp_print(("grid " + total.toString()));
    __bp_print(("try " + ((_r) => "error" in _r ? ((-1)) : _r.ok)(sum(1)).toString()));
    __bp_print(("try " + ((_r) => "error" in _r ? ((-1)) : _r.ok)(sum((-1))).toString()));
    // Two sources, the shorter ending the loop.;
    while (true) {
    const __for88_5_v0 = ["a", "b", "c", "d"];
    const __for88_5_v1 = tens();
    const __for88_5_s1 = (function*() {
        while (true) {
            for (const __for88_5_i1 of __for88_5_v1) {
    yield __for88_5_i1;
}
            break;
        }
    }).call(this);
    for (const s of __for88_5_v0) {
    const _case0 = (() => {
        const _s = __bp_yield_step(__for88_5_s1.next());
        if (_s.tag === "Yield") {
            const { value: t } = _s;
            return __bp_print((s + t.toString()));
        }
        if (_s.tag === "Done") {
            return ({ __bp_break: true });
        }
        throw new Error("case_clause");
    })();
            if (_case0 && _case0.__bp_break) break;
            if (_case0 && _case0.__bp_continue) continue;
}
    break;
}
    while (true) {
    const __for91_5_v0 = tens();
    const __for91_5_v1 = ["p", "q"];
    const __for91_5_s1 = (function*() {
                while (true) {
                    for (const __for91_5_i1 of __for91_5_v1) {
    yield __for91_5_i1;
}
                    break;
                }
            }).call(this);
    for (const t of __for91_5_v0) {
    const _case1 = (() => {
                const _s = __bp_yield_step(__for91_5_s1.next());
                if (_s.tag === "Yield") {
                    const { value: s } = _s;
                    return __bp_print((s + t.toString()));
                }
                if (_s.tag === "Done") {
                    return ({ __bp_break: true });
                }
                throw new Error("case_clause");
            })();
                    if (_case1 && _case1.__bp_break) break;
                    if (_case1 && _case1.__bp_continue) continue;
}
    break;
}
    while (true) {
    const __for94_5_v0 = xs;
    let __for94_5_c1 = 5;
    const __for94_5_e1 = 7;
    for (const x of __for94_5_v0) {
    if ((__for94_5_c1 >= __for94_5_e1)) { break; }
    const r = __for94_5_c1;
    __for94_5_c1 = __bp_int((__for94_5_c1 + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:94:15");
    __bp_print(((("range pair " + x.toString()) + " ") + r.toString()));
}
    break;
}
    // Three sources and the open range as the index.;
    while (true) {
    const __for98_5_v0 = ["x", "y", "z"];
    const __for98_5_v1 = tens();
    const __for98_5_s1 = (function*() {
                        while (true) {
                            for (const __for98_5_i1 of __for98_5_v1) {
    yield __for98_5_i1;
}
                            break;
                        }
                    }).call(this);
    let __for98_5_c2 = 0;
    for (const s of __for98_5_v0) {
    const _case2 = (() => {
                        const _s = __bp_yield_step(__for98_5_s1.next());
                        if (_s.tag === "Yield") {
                            const { value: t } = _s;
                            const i = __for98_5_c2;
                            __for98_5_c2 = __bp_int((__for98_5_c2 + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:98:36");
                            return __bp_print(((((i.toString() + ": ") + s) + " ") + t.toString()));
                        }
                        if (_s.tag === "Done") {
                            return ({ __bp_break: true });
                        }
                        throw new Error("case_clause");
                    })();
                            if (_case2 && _case2.__bp_break) break;
                            if (_case2 && _case2.__bp_continue) continue;
}
    break;
}
    while (true) {
    let __for101_5_c0 = 0;
    const __for101_5_v1 = g.iter();
    for (const item of __for101_5_v1) {
    const i = __for101_5_c0;
    __for101_5_c0 = __bp_int((__for101_5_c0 + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:101:11");
    total = __bp_int((total + __bp_int((i * item), -2147483648, 2147483647, "* on i32 at src/main.bp:102:27")), -2147483648, 2147483647, "+ on i32 at src/main.bp:102:23");
}
    break;
}
    __bp_print(("indexed " + total.toString()));
    // The body is a loop body.;
    while (true) {
    const __for107_5_v0 = ["m", "n", "o", "p"];
    let __for107_5_c1 = 0;
    outer: for (const s of __for107_5_v0) {
    const i = __for107_5_c1;
    __for107_5_c1 = __bp_int((__for107_5_c1 + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:107:40");
    if ((s === "n")) { continue outer; }
    if ((s === "p")) { break outer; }
    __bp_print((("body " + s) + i.toString()));
}
    break;
}
    while (true) {
    let __for112_5_c0 = 0;
    while (true) {
    const i = __for112_5_c0;
    __for112_5_c0 = __bp_int((__for112_5_c0 + 1), -2147483648, 2147483647, "+ on i32 at src/main.bp:112:10");
    if ((i === 2)) { break; }
    __bp_print(("open " + i.toString()));
}
    break;
}
    __bp_print(firstOver(["u", "v", "w"], 15));
    __bp_print(firstOver(["u"], 15));
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
    return "cases/for_loop_sources|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { YieldStep, YieldStep$Yield, YieldStep$Done, tens, countdown, Grid, items, sum, firstOver, run, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
