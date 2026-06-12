----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val #(a, b) = #(12, "hello");
    @print(a, b);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const [ a, b ] = [12, "hello"];
    console.log(a, b);
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
12 hello
```
