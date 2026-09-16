----- SOURCE CODE -- main.bp
```botopink
val v1 = comptime 1 + 1;
fn main() {
    @print(v1);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val v1 = comptime 1 + 1 → 2
```

----- JAVASCRIPT -- main.js
```javascript
const v1 = 2;

function main() {
    console.log(v1);
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
2
```
