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
     const n = name; if (n !== null) { return n; };
    return "unknown";
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
