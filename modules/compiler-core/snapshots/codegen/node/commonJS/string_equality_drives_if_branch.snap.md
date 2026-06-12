----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "yes";
    if (s == "yes") {
        @print(42);
    } else {
        @print(0);
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = "yes";
    (() => { if ((s === "yes")) { return console.log(42); } else { return console.log(0); } })();
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
42
```
