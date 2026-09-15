----- SOURCE CODE -- main.bp
```botopink
fn find(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x > 10) { break x; };
    };
}
fn main() {
    @print(find([5, 8, 15, 20]));
}
```

----- JAVASCRIPT -- main.js
```javascript
function find(arr) {
    return for (const x of arr) {
    (() => { if ((x > 10)) { return return x; } })();
};
}

function main() {
    console.log(find([5, 8, 15, 20]));
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
