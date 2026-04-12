----- SOURCE CODE -- main.bp
```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn calculate() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
}
```

----- JAVASCRIPT -- main.js
```javascript
function calculate() {
    const double = multiply_$0(21);
    const triple = multiply_$1(21);
    const doubleAgain = multiply_$0(10);
}

function multiply_$0(x) {
    const factor = 2;
    return (x * factor);
}

function multiply_$1(x) {
    const factor = 3;
    return (x * factor);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
