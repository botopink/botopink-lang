----- SOURCE CODE -- main.bp
```botopink
pub fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
val result = add(3, 4);
fn main() {
    @print(result);
}
```

----- JAVASCRIPT -- main.js
```javascript
function add(a, b) {
    return (a + b);
}
exports.add = add;

const result = add(3, 4);

function main() {
    console.log(result);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function add(a: i32, b: i32): i32;





```

----- RUN LOG -----
```logs
7
```
