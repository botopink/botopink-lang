----- SOURCE CODE -- main.bp
```botopink
fn check(x: i32) {
    if (x > 0) {
        @print("positive");
    } else {
        @print("non-positive");
    }
}
fn main() {
    check(1);
    check(-1);
}
```

----- JAVASCRIPT -- main.js
```javascript
function check(x) {
    (() => { if ((x > 0)) { return console.log("positive"); } else { return console.log("non-positive"); } })();
}

function main() {
    check(1);
    check((-1));
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
positive
non-positive
```
