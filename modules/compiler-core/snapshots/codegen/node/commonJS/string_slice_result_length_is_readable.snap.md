----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "abcdef";
    val mid = s.slice(1, 5);
    @print(mid.len);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = "abcdef";
    const mid = s.slice(1, 5);
    console.log(mid.len);
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
undefined
```
