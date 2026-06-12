----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "hello";
    @print(s.len + 1);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = "hello";
    console.log((s.len + 1));
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
NaN
```
