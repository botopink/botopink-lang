----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print([1, 2, 3, 4].indexOf(3));
    @print([1, 2, 3].indexOf(99));
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    console.log([1, 2, 3, 4].indexOf(3));
    console.log([1, 2, 3].indexOf(99));
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
2
-1
```
