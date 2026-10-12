----- SOURCE CODE -- main.bp
```botopink
fn getName(name: ?string) -> string {
    if (name) { n ->
        return n;
    };
    return "unknown";
}
```

----- JAVASCRIPT -- main.js
```javascript
function getName(name) {
    { const n = name; if (n != null) { return n; } }
    return "unknown";
}

Object.defineProperty(exports, "__bp_priv__", { value: { getName } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
