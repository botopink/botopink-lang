----- SOURCE CODE -- main.bp
```botopink
val v1 = comptime 1 + 1;
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: (1 + 1) }
];
process.stdout.write(JSON.stringify(results));
```

----- JAVASCRIPT -- main.js
```javascript
const v1 = 2;
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
