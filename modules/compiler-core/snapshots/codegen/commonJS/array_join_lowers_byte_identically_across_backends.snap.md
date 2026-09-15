----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print([10, 20, 30].join(", "));
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    console.log([10, 20, 30].join(", "));
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
10, 20, 30
```
