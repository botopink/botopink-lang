----- SOURCE CODE -- main.bp
```botopink
use { foo, bar } from "mylib";
```

----- JAVASCRIPT -- main.js
```javascript
const { foo, bar } = require("./mylib.js");
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { foo, bar } from "./mylib";

```
