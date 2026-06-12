----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "hi " + "there";
    @print(s.len);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = ("hi " + "there");
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
