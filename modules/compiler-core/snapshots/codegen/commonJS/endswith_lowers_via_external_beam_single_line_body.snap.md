----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "foobar";
    @print(s.endsWith("bar"));
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const s = "foobar";
    console.log(s.endsWith("bar"));
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
true
```
