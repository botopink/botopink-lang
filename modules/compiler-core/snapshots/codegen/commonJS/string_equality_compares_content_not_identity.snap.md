----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val left = "fo" + "o";
    val same = left == "foo";
    val diff = "foo" == "bar";
    if (same) {
        @print(1);
    } else {
        @print(0);
    };
    if (diff) {
        @print(1);
    } else {
        @print(0);
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const left = ("fo" + "o");
    const same = (left === "foo");
    const diff = ("foo" === "bar");
    (() => { if (same) { return console.log(1); } else { return console.log(0); } })();
    (() => { if (diff) { return console.log(1); } else { return console.log(0); } })();
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
1
0
```
