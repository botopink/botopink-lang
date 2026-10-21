----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- JAVASCRIPT -- config.js
```javascript
const PORT = 8080;

exports.PORT = PORT;

const HOST = "localhost";

exports.HOST = HOST;

Object.defineProperty(exports, "__bp_priv__", { value: { PORT, HOST } });
```

----- TYPESCRIPT TYPEDEF -- config.d.ts
```typescript
export declare const PORT: number;


export declare const HOST: string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {config.PORT, config.HOST};
val addr = HOST;
val port = PORT;
```

----- JAVASCRIPT -- main.js
```javascript
const { PORT, HOST } = require("./config.js");

const addr = HOST;

const port = PORT;

Object.defineProperty(exports, "__bp_priv__", { value: { PORT, HOST, addr, port } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { PORT, HOST } from "./config";







```

----- RUN LOG -----
```logs
```
