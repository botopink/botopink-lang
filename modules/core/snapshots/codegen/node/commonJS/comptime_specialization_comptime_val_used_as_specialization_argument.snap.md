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
const fs = require('fs');
const results = [
    { id: "ct_0", value: (10 + 5) }
];
process.stdout.write(JSON.stringify(results));
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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```
