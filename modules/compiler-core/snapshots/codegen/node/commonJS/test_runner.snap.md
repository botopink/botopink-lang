----- SOURCE CODE -- main.bp
```botopink
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

test "addition works" {
    val r = add(2, 3);
    assert r == 5;
}

test {
    assert true;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_assert(cond, msg, loc) {
    if (!cond) {
        const e = new Error(msg || "assertion failed");
        e.__bp_assert_loc = loc;
        throw e;
    }
}

function add(a, b) {
    return (a + b);
}

async function __bp_test_0() {
    const r = add(2, 3);
    __bp_assert((r === 5), null, "main.bp:7");
}

async function __bp_test_1() {
    __bp_assert(true, null, "main.bp:11");
}

const __bp_tests = [
    { name: "addition works", fn: __bp_test_0, loc: "main.bp:5" },
    { name: "test_1", fn: __bp_test_1, loc: "main.bp:10" },
];
async function __bp_run_tests() {
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
TEST main.bp:5 addition works
----- RUN LOG -----
```logs
```
  duration 0ms
  ok   addition works
TEST main.bp:10 test_1
----- RUN LOG -----
```logs
```
  duration 0ms
  ok   test_1
2 passed, 0 failed
```
