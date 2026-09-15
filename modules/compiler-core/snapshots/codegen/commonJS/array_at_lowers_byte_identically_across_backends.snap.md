----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print([10, 20].at(0));
    @print([10].at(5));
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    console.log([10, 20].at(0));
    console.log([10].at(5));
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
10
undefined
```
