----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x = 10;
    @print(x * 2);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const x = 10;
    console.log((x * 2));
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
20
```
