----- SOURCE CODE -- main.bp
```botopink
val result = comptime 10 + 20;
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: (10 + 20) }
];
process.stdout.write(JSON.stringify(results));
```

----- JAVASCRIPT -- main.js
```javascript
const result = 30;
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
