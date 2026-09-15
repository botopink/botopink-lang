----- SOURCE CODE -- main.bp
```botopink
fn negate(v: bool) -> bool {
    return !v;
}
fn main() {
    @print(negate(true));
}
```

----- JAVASCRIPT -- main.js
```javascript
function negate(v) {
    return (!v);
}

function main() {
    console.log(negate(true));
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
false
```
