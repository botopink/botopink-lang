----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("Hello", 42, true);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    console.log("Hello", 42, true);
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
Hello 42 true
```
