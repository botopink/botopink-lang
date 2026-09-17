----- SOURCE CODE -- main.bp
```botopink
fn classify(x: ?i32) -> string {
    if (x == 0) { return "zero"; }
    else if (x != 0) { return "nonzero: " + x; }
    else { return "null"; }
}
fn main() {
    @print(classify(42));
    @print(classify(0));
}
```

----- JAVASCRIPT -- main.js
```javascript
function classify(x) {
    if ((x === 0)) { return "zero"; } else { if ((x !== 0)) { return ("nonzero: " + x); } else { return "null"; } }
}

function main() {
    console.log(classify(42));
    console.log(classify(0));
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
nonzero: 42
zero
```
