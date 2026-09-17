----- SOURCE CODE -- main.bp
```botopink
fn average(xs: Array<f64>) -> f64 {
    var total = 0.0;
    var n = 0.0;
    loop (xs) { x ->
        total = total + x;
        n = n + 1.0;
    };
    return total / n;
}
fn main() {
    val cat = { x, y -> x + y };
    @print(cat("ab", "cd"));
    @print(average([2.0, 4.0, 9.0]));
}
```

----- JAVASCRIPT -- main.js
```javascript
function average(xs) {
    let total = 0.0;
    let n = 0.0;
    for (const x of xs) {
    total = (total + x);
    n = (n + 1.0);
}
    return (total / n);
}

function main() {
    const cat = (x, y) => {
    return (x + y);
};
    console.log(cat("ab", "cd"));
    console.log(average([2.0, 4.0, 9.0]));
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
abcd
5
```
