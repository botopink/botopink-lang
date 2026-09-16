----- SOURCE CODE -- main.bp
```botopink
val result = comptime 10 + 20;
fn main() {
    @print(result);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val result = comptime 10 + 20 → 30
```

----- JAVASCRIPT -- main.js
```javascript
const result = 30;

function main() {
    console.log(result);
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
30
```
