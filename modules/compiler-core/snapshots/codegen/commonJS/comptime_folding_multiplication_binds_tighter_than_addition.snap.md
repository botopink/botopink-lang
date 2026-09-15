----- SOURCE CODE -- main.bp
```botopink
val n = comptime {
    break 2 + 3 * 4;
};
fn main() {
    @print(n);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val n = comptime {
          break 2 + 3 * 4;
      } → 14
```

----- JAVASCRIPT -- main.js
```javascript
const n = 14;

function main() {
    console.log(n);
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
14
```
