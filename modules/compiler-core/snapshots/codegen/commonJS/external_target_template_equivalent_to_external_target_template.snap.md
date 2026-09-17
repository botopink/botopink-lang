----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("filename", "dirname"),
  @External.Node("node:path", "dirname")]
pub declare fn dirname(p: string) -> string;

fn main() {
    @print(dirname("/tmp/notes.txt"));
}
```

----- JAVASCRIPT -- main.js
```javascript
const { dirname } = require("node:path");
exports.dirname = dirname;

function main() {
    console.log(dirname("/tmp/notes.txt"));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function dirname(p: string): string;



```

----- RUN LOG -----
```logs
/tmp
```
