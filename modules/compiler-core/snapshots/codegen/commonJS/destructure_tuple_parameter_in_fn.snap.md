----- SOURCE CODE -- main.bp
```botopink
fn process(#(x, y): #(i32, i32)) -> i32 {
    return x;
}
```

----- JAVASCRIPT -- main.js
```javascript
function process([ x, y ]) {
    return x;
}
process.__bp_arity = 1;

Object.defineProperty(exports, "__bp_priv__", { value: { process } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
