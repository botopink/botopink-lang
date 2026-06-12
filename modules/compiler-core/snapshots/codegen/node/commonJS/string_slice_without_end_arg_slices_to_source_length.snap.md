----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "hello";
    val tail = s.slice(2);
    @print(tail.len);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = "hello";
    const tail = s.slice(2);
    console.log(tail.len);
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
