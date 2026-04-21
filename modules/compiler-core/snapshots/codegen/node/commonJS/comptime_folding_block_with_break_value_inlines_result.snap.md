----- SOURCE CODE -- main.bp
```botopink
val t = comptime {
    break 2 + 22;
};
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: (2 + 22) }
];
process.stdout.write(JSON.stringify(results));
```

----- JAVASCRIPT -- main.js
```javascript
const t = 24;
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
