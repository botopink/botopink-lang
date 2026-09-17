----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "extension"),
  @External.Node("node:path", "extname")]
pub declare fn extname(p: string) -> string;

fn main() {
    @print(extname("docs/readme.md"));
}
```

----- JAVASCRIPT -- main.js
```javascript
const { extname } = require("node:path");
exports.extname = extname;

function main() {
    console.log(extname("docs/readme.md"));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function extname(p: string): string;



```

----- RUN LOG -----
```logs
.md
```
