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
function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw new Error((msg ?? "assertion failed") + " at " + loc); } }

function main() {
    console.log("before");
    __bp_assert_fatal((1 === 2), "boom", "main.bp:3");
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
```
