----- SOURCE CODE -- main.bp
```botopink
val t = comptime {
    break 2 + 22;
};
fn main() {
    @print(t);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val t = comptime {
          break 2 + 22;
      } → 24
```

----- JAVASCRIPT -- main.js
```javascript
const t = 24;

function main() {
    console.log(t);
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
24
```
