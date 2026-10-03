----- SOURCE CODE -- main.bp
```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: i32, value: i32) -> i32 {
    return value * factor;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val base = comptime 10 + 5 → 15
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

const base = 15;

function main() {
    const doubled = scale_$0(base);
    const tripled = scale_$1(base);
    const doubledAgain = scale_$0(100);
}

function scale_$0(value) {
    const factor = 2;
    return __bp_int((value * factor), -2147483648, 2147483647, "* on i32 at main.bp:4:18");
}

function scale_$1(value) {
    const factor = 3;
    return __bp_int((value * factor), -2147483648, 2147483647, "* on i32 at main.bp:4:18");
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
