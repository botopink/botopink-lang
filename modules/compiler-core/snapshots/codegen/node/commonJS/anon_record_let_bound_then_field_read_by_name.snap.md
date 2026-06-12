----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val r = record { code: 7, kind: 11 };
    @print(r.kind);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const r = ({ code: 7, kind: 11 });
    console.log(r.kind);
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
11
```
