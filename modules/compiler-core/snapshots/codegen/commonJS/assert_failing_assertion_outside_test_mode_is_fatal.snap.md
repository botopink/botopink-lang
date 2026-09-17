----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("before");
    assert 1 == 2, "boom";
    @print("after");
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    console.log("before");
    console.assert((1 === 2), "boom");
    console.log("after");
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
before
after

Assertion failed: boom
```
