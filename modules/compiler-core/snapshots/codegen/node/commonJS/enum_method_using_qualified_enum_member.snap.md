----- SOURCE CODE -- main.bp
```botopink
val Status = enum {
    Active,
    Inactive,
    fn isDefault(s: Self) -> string {
        val current = Status.Active;
        return current;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
const Status = Object.freeze({
    Active: "Active",
    Inactive: "Inactive",
    isDefault: function(s) {
        const current = Status.Active;
        return current;
    },
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
