----- SOURCE CODE -- main.bp
```botopink
fn countdown(n: i32) {
    loop (0..n) { i ->
        @print(n - i);
    };
}
fn main() {
    countdown(3);
}
```

----- JAVASCRIPT -- main.js
```javascript
function countdown(n) {
    for (const i of Array.from({length: Math.max(0, (n) - (0))}, (_, __i) => (0) + __i)) {
    console.log((n - i));
}
}

function main() {
    countdown(3);
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
3
2
1
```
