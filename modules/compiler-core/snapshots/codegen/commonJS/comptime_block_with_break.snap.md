----- SOURCE CODE -- main.bp
```botopink
val result = comptime {
    val x = 10;
    break x * 2;
};
fn main() {
    @print(result);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val result = comptime {
          val x = 10;
          break x * 2;
      } → 20
```

----- JAVASCRIPT -- main.js
```javascript
const result = 20;

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
20
```
