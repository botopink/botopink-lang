----- SOURCE CODE -- main.bp
```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: (1 + 2) }
];
process.stdout.write(JSON.stringify(results));
```

----- JAVASCRIPT -- main.js
```javascript
const x = 3;

function double(n) {
    return (n * 2);
}

function main() {
    const r = double(21);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```
