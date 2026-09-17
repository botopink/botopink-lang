----- SOURCE CODE -- main.bp
```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn main() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
    @print(double);
    @print(triple);
    @print(doubleAgain);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const double = multiply_$0(21);
    const triple = multiply_$1(21);
    const doubleAgain = multiply_$0(10);
    console.log(double);
    console.log(triple);
    console.log(doubleAgain);
}

function multiply_$0(x) {
    const factor = 2;
    return (x * factor);
}

function multiply_$1(x) {
    const factor = 3;
    return (x * factor);
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
42
63
20
```
