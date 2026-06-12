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

----- COMPTIME JAVASCRIPT -- main.js
```javascript
(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 8) "[{\"id\":\"ct_0\",\"value\":15}]")
  (func $main (export "_start")
    (i32.store (i32.const 0) (i32.const 8))
    (i32.store (i32.const 4) (i32.const 26))
    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200))))
)
```

----- JAVASCRIPT -- main.js
```javascript
const base = 15;

function main() {
    const doubled = scale_$0(base);
    const tripled = scale_$1(base);
    const doubledAgain = scale_$0(100);
}

function scale_$0(value) {
    const factor = 2;
    return (value * factor);
}

function scale_$1(value) {
    const factor = 3;
    return (value * factor);
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
