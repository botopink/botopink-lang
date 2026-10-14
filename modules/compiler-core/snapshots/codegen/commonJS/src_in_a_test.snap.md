----- SOURCE CODE -- main.bp
```botopink
fn helper() -> i32 { return 1; }
test "src: in a test" {
    val loc = @src();
    @print(loc.file, loc.line, loc.column, loc.fnName);
}
test {
    @print(@src().fnName);
}
```

----- JAVASCRIPT -- main.js
```javascript
class SourceLocation {
    constructor(file, line, column, fnName) {
        this.file = file;
        this.line = line;
        this.column = column;
        this.fnName = fnName;
    }
}
SourceLocation.prototype.__bp = "SourceLocation";

function helper() {
    return 1;
}

Object.defineProperty(exports, "__bp_priv__", { value: { SourceLocation, helper } });
```

----- JAVASCRIPT TEST UNIT -- __test__/main.js
```javascript
const { SourceLocation, helper } = require("../main.js").__bp_priv__;
function __bp_assert(cond, msg, loc) {
    if (!cond) {
        const e = new Error(msg || "assertion failed");
        e.__bp_assert_loc = loc;
        throw e;
    }
}

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

async function __bp_test_0() {
    const loc = new SourceLocation("main.bp", 3, 15, "src: in a test");
    __bp_print(loc.file, loc.line, loc.column, loc.fnName);
}

async function __bp_test_1() {
    __bp_print(new SourceLocation("main.bp", 7, 12, "test_1").fnName);
}

const __bp_tests = [
    { name: "src: in a test", fn: __bp_test_0, loc: "main.bp:2" },
    { name: "test_1", fn: __bp_test_1, loc: "main.bp:6" },
];
async function __bp_run_tests() {
    const process = globalThis.process;
    const filter = process.argv[2] || null;
    const tests = filter ? __bp_tests.filter((t) => t.name.includes(filter)) : __bp_tests;
    let passed = 0, failed = 0;
    const _write = process.stdout.write.bind(process.stdout);
    for (const t of tests) {
        // §T `----- RUN LOG -----` envelope (v0.beta.20 frente-b spec):
        // each test body produces a `TEST <loc> <name>` header + a fenced
        // ```logs``` block capturing its stdout. The `async function`
        // override and restore is per-test so a runtime error inside
        // t.fn() can never strand the override.
        _write("TEST " + t.loc + " " + t.name + "\n");
        _write("----- RUN LOG -----\n```logs\n");
        let _buf = "";
        process.stdout.write = (chunk) => {
            _buf += typeof chunk === "string" ? chunk : chunk.toString();
            return true;
        };
        // §T duration: monotonic millisecond clock around t.fn(); the
        // delta lands on its own `  duration <ms>ms` line between the
        // fence close and the ok/FAIL line. Older parsers that don't
        // recognise the duration line skip it (forward-compatible).
        const _t0 = (typeof performance !== "undefined" && performance.now) ? performance.now() : Date.now();
        let _err = null;
        // Tests are `async function` (see `emitTestFn`) so the
        // runner awaits — a `await flush()` / `await fetch(url)`
        // inside the body resolves before the duration window closes.
        // A sync test pays no observable cost (a resolved Promise
        // is returned and awaited).
        try { await t.fn(); } catch (e) { _err = e; }
        const _t1 = (typeof performance !== "undefined" && performance.now) ? performance.now() : Date.now();
        const _dur_ms = Math.max(0, Math.round(_t1 - _t0));
        process.stdout.write = _write;
        _write(_buf);
        if (_buf.length > 0 && !_buf.endsWith("\n")) _write("\n");
        _write("```\n");
        _write("  duration " + _dur_ms + "ms\n");
        if (_err === null) {
            _write("  ok   " + t.name + "\n");
            passed++;
        } else {
            const loc = _err.__bp_assert_loc || t.loc;
            _write("  FAIL " + t.name + "  (" + _err.message + ")  at " + loc + "\n");
            failed++;
        }
    }
    _write(passed + " passed, " + failed + " failed\n");
    if (failed > 0) process.exit(1);
}
if (require.main === module) __bp_run_tests();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
TEST main.bp:2 src: in a test
----- RUN LOG -----
```logs
main.bp 3 15 src: in a test
```
  duration <ms>ms
  ok   src: in a test
TEST main.bp:6 test_1
----- RUN LOG -----
```logs
test_1
```
  duration <ms>ms
  ok   test_1
2 passed, 0 failed
```
