----- SOURCE CODE -- main.bp
```botopink
val pi2 = comptime {
    break 3.14 * 2.0;
};
fn main() {
    @print(pi2);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val pi2 = comptime {
          break 3.14 * 2.0;
      } → 6.28
```

----- JAVASCRIPT -- main.js
```javascript
const pi2 = 6.28;

function main() {
    console.log(pi2);
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
6.28
```
