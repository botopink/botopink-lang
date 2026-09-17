----- SOURCE CODE -- main.bp
```botopink
fn main() {
    assert 1 + 1 == 2, "arithmetic";
    @print("after");
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    console.assert(((1 + 1) === 2), "arithmetic");
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
after
```
