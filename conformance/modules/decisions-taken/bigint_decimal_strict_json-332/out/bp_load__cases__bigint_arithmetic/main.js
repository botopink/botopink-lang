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

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function __bp_wnorm(v, u, what) {
    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
}

function __bp_wadd(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a + b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) + BigInt(b), u, what);
}

function __bp_wsub(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a - b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) - BigInt(b), u, what);
}

function __bp_bdiv(a, b, what) {
    if (b === 0n) { throw Object.defineProperty(new Error("integer division by zero: " + what), "__bp_panic", { value: true }); }
    return a / b;
}

function __bp_bmod(a, b, what) {
    if (b === 0n) { throw Object.defineProperty(new Error("integer division by zero: " + what), "__bp_panic", { value: true }); }
    return a % b;
}

// behavior bigint
//   fn of(...)
//   fn parse(...)
//   fn toString(...)
//   fn toI64(...)
//   fn toF64(...)
BigInt.prototype.toI64 = function() { return ((__v) => { if (__v >= -9223372036854775808n && __v <= 9223372036854775807n) { return (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; } throw new Error("integer overflow: toI64: " + __v + " does not fit i64"); })(this.valueOf()); };
BigInt.prototype.toF64 = function() { return ((__v) => { const __f = Number(__v); if (typeof __v !== "bigint" || BigInt(__f) === __v) { return __f; } throw new Error("integer overflow: toF64: " + __v + " has no exact f64"); })(this.valueOf()); };

//// Decision 332 — `bigint` is an integer of any size, one value on the four targets: erlang and

//// beam hold the VM's integer, commonJS a `BigInt`, wasm its runtime library. `+ - * / %`, unary

//// `-`, `+=`, the comparisons and `==` over two `bigint`s never overflow; `/` truncates toward

//// zero and `%` takes the dividend's sign; `bigint.of` / `bigint.parse` cross in, `toString`,

//// `toI64` and `toF64` out. The parent binary refused the `n` suffix.

function power(base, times) {
    let x = 1n;
    let i = 0;
    while ((i < times)) {
    x = (x * base);
    i = __bp_int((i + 1), -2147483648, 2147483647, "+= on i32 at src/main.bp:14:9");
}
    return x;
}

function main() {
    const two = 2n;
    const top = power(two, 101);
    __bp_print(top);
    const a = 1234567890123456789012345678901234567890n;
    const b = 9876543210987654321098765432109876543210n;
    __bp_print((a * b));
    __bp_print((b - (a * 8n)));
    __bp_print((a + b));
    __bp_print(__bp_bdiv((-7n), 2n, "/ on bigint at src/main.bp:28:15"));
    __bp_print(__bp_bdiv(7n, (-2n), "/ on bigint at src/main.bp:29:14"));
    __bp_print(__bp_bmod((-7n), 2n, "% on bigint at src/main.bp:30:15"));
    __bp_print(__bp_bmod(7n, (-2n), "% on bigint at src/main.bp:31:14"));
    __bp_print(__bp_bdiv((-b), a, "/ on bigint at src/main.bp:32:14"));
    __bp_print(__bp_bmod((-b), a, "% on bigint at src/main.bp:33:14"));
    __bp_print((__bp_bdiv((a * b), b, "/ on bigint at src/main.bp:34:17") === a));
    __bp_print(__bp_bmod((((a * b) + 7n)), b, "% on bigint at src/main.bp:35:24"));
    __bp_print(__bp_bdiv(top, 1000000007n, "/ on bigint at src/main.bp:36:15"));
    __bp_print(__bp_bmod(top, 1000000007n, "% on bigint at src/main.bp:37:15"));
    __bp_print((a < b));
    __bp_print((b <= a));
    __bp_print(((-b) < a));
    __bp_print((a === 1234567890123456789012345678901234567890n));
    __bp_print((a !== b));
    __bp_print(top.toString());
    __bp_print(("2^101 = " + top));
    let sum = 0n;
    sum += a;
    sum += b;
    __bp_print(sum);
    __bp_print((-sum));
    __bp_print(((0n - sum) + sum));
    __bp_print((BigInt(9223372036854775807n) + 1n));
    __bp_print((BigInt(__bp_wsub((-9223372036854775807n), 1, 0, "- on i64 at src/main.bp:52:43")) - 1n));
    __bp_print((BigInt((-5)) * 3n));
    __bp_print(BigInt(12));
    __bp_print(((_r) => "error" in _r ? (0n) : _r.ok)(((__s) => /^[+-]?[0-9]+$/.test(__s) ? { ok: BigInt(__s) } : { error: 'bigint.parse: "' + __s + '" is not an integer' })("-123456789012345678901234567890")));
    __bp_print(((_r) => "error" in _r ? (0n) : _r.ok)(((__s) => /^[+-]?[0-9]+$/.test(__s) ? { ok: BigInt(__s) } : { error: 'bigint.parse: "' + __s + '" is not an integer' })("+42")));
    __bp_print(((_r) => "error" in _r ? ((-1n)) : _r.ok)(((__s) => /^[+-]?[0-9]+$/.test(__s) ? { ok: BigInt(__s) } : { error: 'bigint.parse: "' + __s + '" is not an integer' })("12x")));
    __bp_print(((_r) => "error" in _r ? ((-2n)) : _r.ok)(((__s) => /^[+-]?[0-9]+$/.test(__s) ? { ok: BigInt(__s) } : { error: 'bigint.parse: "' + __s + '" is not an integer' })("")));
    __bp_print(((_r) => "error" in _r ? ((-3n)) : _r.ok)(((__s) => /^[+-]?[0-9]+$/.test(__s) ? { ok: BigInt(__s) } : { error: 'bigint.parse: "' + __s + '" is not an integer' })("-")));
    const near = 4611686018427387904n;
    __bp_print(__bp_wadd(near.toI64(), 1, 0, "+ on i64 at src/main.bp:61:24"));
    __bp_print((((-near) * 2n)).toI64());
    __bp_print_as(["f"], (1024n).toF64());
    __bp_print(Object.is(((power(two, 80) * 3n)).toF64(), 3626777458843887524118528.0));
    __bp_print((0xFFn * 0x100n));
    __bp_print((1_000_000n * 1_000_000n));
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
    return "cases/bigint_arithmetic|*";
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

Object.defineProperty(exports, "__bp_priv__", { value: { power, main, __bp_loaded_main, __bp_loaded_main_off, __bp_loaded_info } });
