----- SOURCE CODE -- main.bp
```botopink
fn label(a: string, b: string) -> string {
    return "${a}-${b}";
}
```

----- JAVASCRIPT -- main.js
```javascript
function label(a, b) {
    return ((("" + a) + "-") + b);
}

Object.defineProperty(exports, "__bp_priv__", { value: { label } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
