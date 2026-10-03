----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(string)-> string = {s ->
        return s;
    };
    return func("hello");
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const func = (s) => {
    return s;
};
    return func("hello");
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
