----- SOURCE CODE -- main.bp
```botopink
fn abs(n: i32) -> i32 {
    val result = if (n < 0) -n else n;
    return result;
}
fn main() {
    @print(abs(-5));
    @print(abs(3));
}
```

----- JAVASCRIPT -- main.js
```javascript
function abs(n) {
    const result = (() => { if ((n < 0)) { return (-n); } else { return n; } })();
    return result;
}

function main() {
    console.log(abs((-5)));
    console.log(abs(3));
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
5
3
```
