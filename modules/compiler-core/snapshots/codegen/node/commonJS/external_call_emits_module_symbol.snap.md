----- SOURCE CODE -- main.bp
```botopink
#[@external(erlang, "string", "length"),
  @external(node, "./gleam_stdlib.mjs", "string_length")]
pub declare fn str_length(s: string) -> i32;

fn main() {
    @print(str_length("hello"));
}
```

----- JAVASCRIPT -- main.js
```javascript
const { string_length: str_length } = require("./gleam_stdlib.mjs");
exports.str_length = str_length;

function main() {
    console.log(str_length("hello"));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function str_length(s: ): i32;



```

----- RUN LOG -----
```logs
```
