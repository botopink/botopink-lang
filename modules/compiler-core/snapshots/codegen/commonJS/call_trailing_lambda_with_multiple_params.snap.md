----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32) -> i32 {
    @todo();
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function calc(factor) {
    (() => { throw Object.defineProperty(new Error("not implemented"), '__bp_panic', { value: true }) })();
}

function main() {
    const r = calc(2, (a, b) => {
    return 0;
});
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { calc, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
