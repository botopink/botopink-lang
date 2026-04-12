----- SOURCE CODE -- main.bp
```botopink
val pi2 = comptime {
    break 3.14 * 2.0;
};
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: (3.14 * 2.0) }
];
process.stdout.write(JSON.stringify(results));
```

----- JAVASCRIPT -- main.js
```javascript
const pi2 = 6.28;
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
