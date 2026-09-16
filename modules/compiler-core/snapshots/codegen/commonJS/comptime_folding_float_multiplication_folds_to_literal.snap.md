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
      } → 0
```

----- JAVASCRIPT -- main.js
```javascript
const pi2 = 0;

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
0
```
