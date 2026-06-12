----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val outer = record { span: record { start: 1, end: 2 }, kind: 3 };
    return outer;
}
```

----- JAVASCRIPT -- main.js
```javascript
function make() {
    const outer = ({ span: ({ start: 1, end: 2 }), kind: 3 });
    return outer;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
