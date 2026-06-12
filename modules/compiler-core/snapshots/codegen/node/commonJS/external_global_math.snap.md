----- SOURCE CODE -- main.bp
```botopink
#[@external(erlang, "math", "floor"),
  @external(node, "Math", "floor")]
pub declare fn floor(n: f64) -> f64;

fn main() {
    @print(floor(1.7));
}
```

----- JAVASCRIPT -- main.js
```javascript
const floor = Math.floor;
exports.floor = floor;

function main() {
    console.log(floor(1.7));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function floor(n: ): f64;



```

----- RUN LOG -----
```logs
1
```
