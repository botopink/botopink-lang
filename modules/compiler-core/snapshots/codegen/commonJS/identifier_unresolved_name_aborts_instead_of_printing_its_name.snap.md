----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val assert 42 = answer catch 0;
    @print("unreachable");
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    (() => { const _match = answer; if ((_match === 42)) { return _match; } else { return 0; } })();
    console.log("unreachable");
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
