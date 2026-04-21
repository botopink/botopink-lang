----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> {
      case 1 {
          0    -> 54;
          _ -> 1;
      };
   };
   _ -> 1;
};
```

----- JAVASCRIPT -- main.js
```javascript
const result = (() => {
    const _s = 42;
    if (_s === 0) {
        (() => {
            const _s = 1;
            if (_s === 0) return 54;
            return 1;
        })();
    }
    return 1;
})();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
