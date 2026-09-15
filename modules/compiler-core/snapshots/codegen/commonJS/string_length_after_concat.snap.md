----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "ab" + "cdef";
    @print(s.len);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = ("ab" + "cdef");
    console.log(s.len);
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
