----- SOURCE CODE -- main.bp
```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val x = comptime 1 + 2 → 3
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

const x = 3;

function double(n) {
    return __bp_int((n * 2), -2147483648, 2147483647, "* on i32 at main.bp:4:14");
}

function main() {
    const r = double(21);
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
