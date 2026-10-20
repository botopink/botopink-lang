----- SOURCE CODE -- main.bp
```botopink
fn execute(comptime slug: string, input: i32) -> i32 {
    return input + 0;
}

fn main() -> void {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
    val r3 = execute("calc", 5);
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
    const r3 = execute_$0(5);
}

function execute_$0(input) {
    return __bp_int((input + 0), -2147483648, 2147483647, "+ on i32 at main.bp:2:18");
}

function execute_$1(input) {
    return __bp_int((input + 0), -2147483648, 2147483647, "+ on i32 at main.bp:2:18");
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { main, execute_$0, execute_$1 } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
