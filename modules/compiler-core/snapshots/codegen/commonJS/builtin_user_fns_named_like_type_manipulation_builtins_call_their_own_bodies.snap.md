----- SOURCE CODE -- main.bp
```botopink
fn pick(n: i32) -> i32 { return n + 1; }
fn omit(n: i32) -> i32 { return n + 2; }
fn partial(n: i32) -> i32 { return n + 3; }
fn mergeRecords(a: i32, b: i32) -> i32 { return a + b; }
fn mapFields(n: i32) -> i32 { return n * 2; }
fn main() {
    @print(pick(1));
    @print(omit(1));
    @print(partial(1));
    @print(mergeRecords(2, 3));
    @print(mapFields(3));
}
```

----- JAVASCRIPT -- main.js
```javascript
function pick(n) {
    return (n + 1);
}

function omit(n) {
    return (n + 2);
}

function partial(n) {
    return (n + 3);
}

function mergeRecords(a, b) {
    return (a + b);
}

function mapFields(n) {
    return (n * 2);
}

function main() {
    console.log(pick(1));
    console.log(omit(1));
    console.log(partial(1));
    console.log(mergeRecords(2, 3));
    console.log(mapFields(3));
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
2
3
4
5
6
```
