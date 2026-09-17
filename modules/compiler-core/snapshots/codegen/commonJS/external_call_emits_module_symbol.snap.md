----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "basename"),
  @External.Node("node:path", "basename")]
pub declare fn basename(p: string) -> string;

fn main() {
    @print(basename("/tmp/notes.txt"));
}
```

----- JAVASCRIPT -- main.js
```javascript
const { basename } = require("node:path");
exports.basename = basename;

function main() {
    console.log(basename("/tmp/notes.txt"));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function basename(p: string): string;



```

----- RUN LOG -----
```logs
notes.txt
```
