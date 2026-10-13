----- SOURCE CODE -- main.bp
```botopink
fn run() {
    @todo();
}
fn main() {
    run { x ->
        return "done";
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function run() {
    (() => { throw Object.defineProperty(new Error("not implemented"), '__bp_panic', { value: true }) })();
}

function main() {
    run((x) => {
    return "done";
});
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { run, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
