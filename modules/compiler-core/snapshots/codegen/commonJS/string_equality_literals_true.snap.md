----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val same = "foo" == "foo";
    if (same) {
        @print(1);
    } else {
        @print(0);
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const same = ("foo" === "foo");
    (() => { if (same) { return console.log(1); } else { return console.log(0); } })();
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
```
