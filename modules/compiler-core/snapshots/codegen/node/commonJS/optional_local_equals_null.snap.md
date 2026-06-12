----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x: ?i32 = null;
    if (x == null) {
        @print(1);
    } else {
        @print(0);
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const x = null;
    (() => { if ((x == null)) { return console.log(1); } else { return console.log(0); } })();
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
