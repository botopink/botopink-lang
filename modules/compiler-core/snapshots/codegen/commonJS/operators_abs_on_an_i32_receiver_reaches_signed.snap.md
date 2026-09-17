----- SOURCE CODE -- main.bp
```botopink
fn mag(n: i32) -> i32 {
    return n.abs();
}
fn main() {
    @print(mag(-7));
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Signed extends Integer
//   fn abs(...)
Number.prototype.abs = function() { return Math.abs(this.valueOf()); };

function mag(n) {
    return n.abs();
}

function main() {
    console.log(mag((-7)));
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
7
```
