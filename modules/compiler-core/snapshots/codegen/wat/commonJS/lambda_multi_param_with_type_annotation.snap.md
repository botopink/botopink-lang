----- SOURCE CODE -- main.bp
```botopink
fn main() -> i32 {
    val add: fn(i32,i32)-> i32 = {a, b ->
        return a + b;
    };
    return add(10, 20);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const add = (a, b) => {
    return (a + b);
};
    return add(10, 20);
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
```
