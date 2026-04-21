----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32) -> i32 {
    @todo();
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function calc(factor) {
    (() => { throw new Error("not implemented") })();
}

function main() {
    const r = calc(2, (a, b) => {
    return 0;
});
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
