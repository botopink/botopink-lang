----- SOURCE CODE -- main.bp
```botopink
pub fn max(a: i32, b: i32) -> i32 {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}
fn main() {
    @print(max(3, 7));
}
```

----- JAVASCRIPT -- main.js
```javascript
function max(a, b) {
     if ((a < b)) { return b; } else { return a; };
}
exports.max = max;

function main() {
    console.log(max(3, 7));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function max(a: , b: ): i32;



```

----- RUN LOG -----
```logs
7
```
