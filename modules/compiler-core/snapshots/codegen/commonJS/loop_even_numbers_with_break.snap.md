----- SOURCE CODE -- main.bp
```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
fn main() {
    @print(processamento);
}
```

----- JAVASCRIPT -- main.js
```javascript
const processamento = for (const i of Array.from({length: Math.max(0, (10) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if (((i % 2) === 0)) { return return i; } })();
};

function main() {
    console.log(processamento);
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
