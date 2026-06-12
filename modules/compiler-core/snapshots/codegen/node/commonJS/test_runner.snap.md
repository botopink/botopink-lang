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

function __bp_test_0() {
    const r = add(2, 3);
    __bp_assert((r === 5), null, "main.bp:7");
}

function __bp_test_1() {
    __bp_assert(true, null, "main.bp:11");
}

const __bp_tests = [
    { name: "addition works", fn: __bp_test_0, loc: "main.bp:5" },
    { name: "test_1", fn: __bp_test_1, loc: "main.bp:10" },
];
function __bp_run_tests() {
    const filter = process.argv[2] || null;
    const tests = filter ? __bp_tests.filter((t) => t.name.includes(filter)) : __bp_tests;
    console.log("running " + tests.length + " tests");
    let passed = 0, failed = 0;
    for (const t of tests) {
        try {
            t.fn();
            console.log("  ok   " + t.name);
            passed++;
        } catch (e) {
            const loc = e.__bp_assert_loc || t.loc;
            console.log("  FAIL " + t.name + "  (" + e.message + ")  at " + loc);
            failed++;
        }
    }
    console.log(passed + " passed, " + failed + " failed");
    if (failed > 0) process.exit(1);
}
if (require.main === module) __bp_run_tests();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
running 2 tests
  ok   addition works
  ok   test_1
2 passed, 0 failed
```
