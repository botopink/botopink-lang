----- SOURCE CODE -- main.bp
```botopink
fn main() -> bool {
    return isEven(10);
}

fn isEven(n: i32) -> bool {
    if (n == 0) { return true; };
    return isOdd(n - 1);
}

fn isOdd(n: i32) -> bool {
    if (n == 0) { return false; };
    return isEven(n - 1);
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

function main() {
    return isEven(10);
}

function isEven(n) {
    if ((n === 0)) { return true; }
    return isOdd(__bp_int((n - 1), -2147483648, 2147483647, "- on i32 at main.bp:7:20"));
}

function isOdd(n) {
    if ((n === 0)) { return false; }
    return isEven(__bp_int((n - 1), -2147483648, 2147483647, "- on i32 at main.bp:12:21"));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
