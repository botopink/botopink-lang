----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val name = "ana";
    @print("hi", name, 42, [1, 2]);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const name = "ana";
    console.log("hi", name, 42, [1, 2]);
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
hi ana 42 [ 1, 2 ]
```
