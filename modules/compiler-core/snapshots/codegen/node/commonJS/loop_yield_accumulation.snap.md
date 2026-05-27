----- SOURCE CODE -- main.bp
```botopink
fn doubles(arr: i32[]) -> i32[] {
    return loop (arr) { x ->
        yield x * 2;
    };
}
fn main() {
    @print(doubles([1, 2, 3]));
}
```

----- JAVASCRIPT -- main.js
```javascript
function doubles(arr) {
    return arr.map((x) => {
    return (x * 2);
});
}

function main() {
    console.log(doubles([1, 2, 3]));
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
[ 2, 4, 6 ]
```
