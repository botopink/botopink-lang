----- SOURCE CODE -- main.bp
```botopink
loop (0..10) { i ->
    @print(i);
};
```

----- JAVASCRIPT -- main.js
```javascript
const _loop = for (const [i] of Object.entries(0..10)) {
    console.log(i);
};
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
/home/ericfillipe/develop/botopink-lang/modules/compiler-core/tmp_run.js:1
const _loop = for (const [i] of Object.entries(0..10)) {
              ^^^

SyntaxError: Unexpected token 'for'
    at wrapSafe (node:internal/modules/cjs/loader:1762:18)
    at Module._compile (node:internal/modules/cjs/loader:1805:20)
    at Object..js (node:internal/modules/cjs/loader:1971:10)
    at Module.load (node:internal/modules/cjs/loader:1552:32)
    at Module._load (node:internal/modules/cjs/loader:1354:12)
    at wrapModuleLoad (node:internal/modules/cjs/loader:255:19)
    at Module.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:154:5)
    at node:internal/main/run_main_module:33:47

Node.js v25.8.0
```
