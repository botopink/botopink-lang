----- SOURCE CODE -- main.bp
```botopink
fn main() {
    assert 1 + 1 == 2, "arithmetic";
    @print("after");
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw new Error((msg ?? "assertion failed") + " at " + loc); } }

function main() {
    __bp_assert_fatal(((1 + 1) === 2), "arithmetic", "main.bp:2");
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
