----- SOURCE CODE -- main.bp
```botopink
fn firstChar(s: string) -> ?string { @todo(); }
fn main() {
    val s = firstChar("abc").expect("");
}
```

----- JAVASCRIPT -- main.js
```javascript
function firstChar(s) {
    (() => { throw new Error("not implemented") })();
}

function main() {
    const s = ((_o) => _o != null ? _o : (""))(firstChar("abc"));
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
